package src.hxyarn.compiler;

import src.hxyarn.compiler.Stmt.StmtDeclare;
import src.hxyarn.compiler.Stmt.StmtNode;
import src.hxyarn.compiler.Stmt.StmtFileHashtag;
import src.hxyarn.program.types.BuiltInTypes;
import src.hxyarn.program.types.IType;

class DeclaractionVisitor extends BaseVisitor {
	var existingDeclarations:Array<Declaration> = [];
	var currentNodeName:String;
	var currentNodeContext:StmtNode;
	var sourceFileName:String;
	var types:Array<IType> = [];

	public var newDeclarations:Array<Declaration> = [];

	var fileTags:Array<String> = [];

	var keywordsToBuiltinTypes = [
		"string" => BuiltInTypes.string,
		"number" => BuiltInTypes.number,
		"bool" => BuiltInTypes.boolean
	];

	function declaractions():Array<Declaration> {
		return existingDeclarations.concat(newDeclarations);
	}

	// TODO tokens for commments
	public function new(sourceFileName:String, existingDeclaractions:Array<Declaration>, typeDeclarations:Array<IType>) {
		this.existingDeclarations = existingDeclaractions;
		this.newDeclarations = new Array<Declaration>();
		this.fileTags = new Array<String>();
		this.sourceFileName = sourceFileName;
		this.types = typeDeclarations;
	}

	public override function visitFileHashtag(stmt:StmtFileHashtag):Dynamic {
		this.fileTags.push(stmt.text.lexeme);
		return null;
	}

	public override function visitNode(stmt:StmtNode):Dynamic {
		currentNodeContext = stmt;

		for (header in stmt.headers) {
			if (header.id.lexeme == "title") {
				currentNodeName = header.value.lexeme;
			}
		}

		var body = stmt.body;

		if (body != null)
			body.accept(this);

		return null;
	}

	public override function visitDeclare(stmt:StmtDeclare):Dynamic {
		var description = ""; // TODO get by comment

		var variableName = stmt.variable.varId.lexeme;

		var existingExplicitDeclaration = declaractions().filter(function(d:Declaration) {
			return d.isImplicit == false && d.name == variableName;
		})[0];

		if (existingExplicitDeclaration != null) {
			// TODO logging
			return BuiltInTypes.undefined;
		}

		var constantValueVistitor = new ConstantValueVisitor(stmt, sourceFileName, types);
		var constantValue = constantValueVistitor.visitDeclare(stmt);
		var value = cast(constantValue, src.hxyarn.program.Value);

		// TODO Typed Declare statement?
		var positionInFile = stmt.variable.varId.line;
		var nodePositionInFile = 0; // TODO get this

		var declaration = new Declaration();
		declaration.name = variableName;
		declaration.type = value.type;
		declaration.defaultValue = value.internalValue;
		declaration.description = description;
		declaration.sourceFileName = sourceFileName;
		declaration.sourceFileLine = positionInFile;
		declaration.sourceNodeName = currentNodeName;
		declaration.sourceNodeLine = nodePositionInFile;
		declaration.isImplicit = false;

		return value.type;
	}
}
