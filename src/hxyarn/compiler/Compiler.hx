package hxyarn.compiler;

import hxyarn.program.types.IType;
import hxyarn.program.Library;
import hxyarn.program.types.FunctionType;
import hxyarn.compiler.DeclarationVisitor.DeclaractionVisitor;
import hxyarn.program.types.BuiltInTypes;
import hxyarn.compiler.Stmt.StmtDialogue;
import hxyarn.program.Operand;
import hxyarn.program.Instruction;
import hxyarn.program.Node;
import hxyarn.program.Program;

class Compiler {
	public var currentNode:Node;

	var labelCount = 0;
	var rawTextNode = false; // TODO
	var program:Program;
	var fileName:String;
	var library:Library;
	var variableDeclarations:Array<Declaration>;
	var fileParseResult:StmtDialogue;
	var trackingNodes:Array<String>;

	public function new(fileName:String, fileParseResult:StmtDialogue) {
		program = new Program();
		this.fileName = fileName;
		this.fileParseResult = fileParseResult;
	}

	public static function compile(job:CompilationJob):CompilationResult {
		var results = new Array<CompilationResult>();
		var derivedVariableDeclarations = new Array<Declaration>();
		var knownVariableDeclarations = new Array<Declaration>();
		var typeDelaractions = BuiltInTypes.all;

		if (job.variableDelarations != null) {
			knownVariableDeclarations = job.variableDelarations;
		}

		// TODO Diagnotics

		if (job.library != null) {
			// TODO Diagnotsics
			var declarations = getDeclaractionsFromLibrary(job.library);
			knownVariableDeclarations = knownVariableDeclarations.concat(declarations);
		}

		var parsedFiles = new Array<StmtDialogue>();
		var stringTableManager = new StringTableManager();

		for (file in job.files) {
			var tokens = Scanner.scan(file.source);
			var dialogue = new StmtParser(tokens).parse();

			parsedFiles.push(dialogue);
			registerStrings(file.fileName, stringTableManager, dialogue);
		}

		var fileTags = new Map<String, Array<String>>();

		for (i => parsedFile in parsedFiles) {
			var file = job.files[i];
			var declaractionVisitor = new DeclaractionVisitor(file.fileName, knownVariableDeclarations, typeDelaractions);
			declaractionVisitor.visitDialogue(parsedFile);
			derivedVariableDeclarations = derivedVariableDeclarations.concat(declaractionVisitor.newDeclarations);
			knownVariableDeclarations = knownVariableDeclarations.concat(declaractionVisitor.newDeclarations);
			// TODO Diagnostics

			fileTags.set(file.fileName, declaractionVisitor.fileTags);
		}

		for (i => parsedFile in parsedFiles) {
			var file = job.files[i];
			var checker = new TypeCheckVisitor(file.fileName, knownVariableDeclarations, typeDelaractions);
			checker.visitDialogue(parsedFile);
			derivedVariableDeclarations = derivedVariableDeclarations.concat(checker.newDeclarations);
			knownVariableDeclarations = knownVariableDeclarations.concat(checker.newDeclarations);

			// TODO Diagnostics
			// TODO Validate Expressions
		}

		// determining the nodes we need to track visits on
		// this needs to be done before we finish up with declarations
		// so that any tracking variables are included in the compiled declarations
		var trackingNodes = new Array<String>();
		var ignoringNodes = new Array<String>();
		for (parsedFile in parsedFiles) {
			var thingy = new NodeTrackingVisitor(trackingNodes, ignoringNodes);
			thingy.visitDialogue(parsedFile);
		}

		// removing all nodes we are told explicitly to not track
		trackingNodes = trackingNodes.filter(function(n) {
			return !ignoringNodes.contains(n);
		});

		var trackingDeclarations = new Array<Declaration>();
		for (node in trackingNodes) {
			trackingDeclarations.push(Declaration.createVariable(Library.generateUniqueVisitedVariableForNode(node), BuiltInTypes.number, 0,
				'The generated variable for tracking visits of node $node'));
		}

		knownVariableDeclarations = knownVariableDeclarations.concat(trackingDeclarations);
		derivedVariableDeclarations = derivedVariableDeclarations.concat(trackingDeclarations);

		for (i => parsedFile in parsedFiles) {
			var file = job.files[i];
			var compilationResult = generateCode(parsedFile, file.fileName, knownVariableDeclarations, job, stringTableManager, trackingNodes);
			results.push(compilationResult);
		}

		var finalResults = CompilationResult.combineCompilationResults(results, stringTableManager);

		for (declaration in knownVariableDeclarations) {
			if (Std.isOfType(declaration.type, FunctionType))
				continue;

			if (declaration.type == BuiltInTypes.undefined)
				continue;

			var value:Operand;

			if (declaration.defaultValue == null) {
				// TODO: Diagnostic
				continue;
			}

			if (declaration.type == BuiltInTypes.string) {
				value = Operand.fromString(declaration.defaultValue);
			} else if (declaration.type == BuiltInTypes.number) {
				value = Operand.fromFloat(cast(declaration.defaultValue, Float));
			} else if (declaration.type == BuiltInTypes.boolean) {
				value = Operand.fromBool(cast(declaration.defaultValue, Bool));
			} else {
				throw 'Cannot create an initial value for type ${declaration.type.name}';
			}

			finalResults.program.initialValues.set(declaration.name, value);
		}

		finalResults.declarations = derivedVariableDeclarations;
		finalResults.tags = fileTags;

		return finalResults;
	}

	static function generateCode(parsedFile:StmtDialogue, fileName:String, variableDeclarations:Array<Declaration>, job:CompilationJob,
			stringTableManager:StringTableManager, trackingNodes:Array<String>):CompilationResult {
		var compiler = new Compiler(fileName, parsedFile);
		compiler.library = job.library;
		compiler.variableDeclarations = variableDeclarations;
		compiler.trackingNodes = trackingNodes;
		compiler.compileParsedFile();

		// TODO DebugInfo

		var result = new CompilationResult();
		result.program = compiler.program;
		result.stringTable = stringTableManager.stringTable;

		return result;
	}

	function compileParsedFile() {
		for (node in this.fileParseResult.nodes) {
			currentNode = new Node();
			for (header in node.headers) {
				if (header.id.lexeme == "title") {
					currentNode.name = StringTools.trim(header.value.lexeme);
				}
				if (header.id.lexeme == "tags") {
					var tags = [];
					if (header.value != null)
						tags = header.value.lexeme.split(',');

					currentNode.tags = currentNode.tags.concat(tags);
				}
			}
			currentNode.labels.set(registerLabel(), currentNode.instructions.length);

			var track = trackingNodes.contains(currentNode.name) ? Library.generateUniqueVisitedVariableForNode(currentNode.name) : null;
			var visitor = new CodeGenerationVisitor(this, track);
			visitor.visitNode(node);
			var hasRemainingOptions = false;
			for (instruction in currentNode.instructions) {
				if (instruction.opcode == OpCode.ADD_OPTIONS)
					hasRemainingOptions = true;

				if (instruction.opcode == OpCode.SHOW_OPTIONS)
					hasRemainingOptions = false;
			}

			if (hasRemainingOptions) {
				emit(OpCode.SHOW_OPTIONS, []);
				emit(OpCode.RUN_NODE, []);
			} else {
				if (track != null) {
					CodeGenerationVisitor.generateTrackingCode(this, track);
				}
				emit(OpCode.STOP, []);
			}

			program.nodes.set(currentNode.name, currentNode);
		}
	}

	static function registerStrings(fileName:String, stringTableManager:StringTableManager, dialogue:StmtDialogue) {
		var visitor = new StringTableGeneratorVisitor(fileName, stringTableManager);
		visitor.visitDialogue(dialogue);
	}

	public function emit(opCode:OpCode, operands:Array<Operand>) {
		var instruction = new Instruction();
		instruction.opcode = opCode;
		instruction.operands = operands;

		currentNode.instructions.push(instruction);
	}

	public function registerLabel(?commentary:String = null) {
		return 'L${labelCount++}$commentary';
	}

	public static function getLineIdTag(hashtags:Array<String>):String {
		if (hashtags == null)
			return null;

		for (hashtag in hashtags) {
			if (StringTools.startsWith(hashtag, "line:"))
				return hashtag;
		}

		return null;
	}

	static function getDeclaractionsFromLibrary(library:Library):Array<Declaration> {
		var declarations = new Array<Declaration>();

		for (func in library.functions) {
			// we don't handle non built in types here
			if (!Std.isOfType(func.returnType, IType))
				continue;

			var functionType = new FunctionType();
			var includeMethod = true;

			// TODO Param Types
			for (i in 0...func.paramCount)
				functionType.parameters.push(BuiltInTypes.any);

			functionType.returnType = func.returnType;

			var decl = new Declaration();
			decl.name = func.name;
			decl.type = functionType;
			decl.sourceFileLine = -1;
			decl.sourceNodeLine = -1;
			decl.sourceFileName = "External";

			declarations.push(decl);
		}

		return declarations;
	}
}
