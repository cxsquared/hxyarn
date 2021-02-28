package src.hxyarn.compiler;

import haxe.Exception;
import src.hxyarn.program.VirtualMachine.TokenType;
import src.hxyarn.program.Operand;
import src.hxyarn.program.Instruction;
import sys.FileSystem;
import src.hxyarn.program.Node;
import sys.io.File;
import haxe.Json;
import src.hxyarn.program.Program;

class Compiler {
	var invalidNodeTilteNameRegex = ~/[\[<>\]{}\|:\s#\$]/i;
	var labelCount = 0;

	public var currentNode:Node;

	var rawTextNode = false;
	var program:Program;
	var fileName:String;
	var containsImplicitStringTags:Bool;
	var stringCount = 0;
	var stringTable = new Map<String, StringInfo>();
	var ifStatementEndLabels = new List<String>();
	var generateClauseLabels = new List<String>();

	public function new(fileName:String) {
		program = new Program();
		this.fileName = fileName;
	}

	public static function compileFile(path:String):{program:Program, stringTable:Map<String, StringInfo>} {
		var json = Json.parse(File.getContent(path));
		var directories = FileSystem.absolutePath(path).split('/');
		var fileName = directories[directories.length - 1];

		return compileJson(json, fileName);
	}

	static function compileJson(json:Dynamic, fileName:String):{
		program:Program,
		stringTable:Map<String, StringInfo>
	} {
		// lexer
		// tokeninze
		// parse
		// tree

		var compiler = new Compiler(fileName);

		compiler.compile(json);

		return {
			program: compiler.program,
			stringTable: compiler.stringTable
		};
	}

	function compile(json:Array<Dynamic>) {
		for (node in json) {
			var node = parseNode(node);
			program.nodes.set(node.name, node);
		}
	}

	function parseNode(obj:Dynamic):Node {
		var node = new Node();
		currentNode = node;

		node.name = obj.title;
		if (invalidNodeTilteNameRegex.match(node.name)) {
			throw new Exception('The node \'${node.name}\' contains illegal characters in the title.');
		}

		currentNode.labels.set(registerLabel(), currentNode.instructions.length);

		var tags = cast(obj.tags, String).split(",");
		node.tags = new Array<String>();
		for (tag in tags) {
			node.tags.push(StringTools.trim(tag));
		}

		var lines = cast(obj.body, String).split('\r\n');
		for (index => line in lines) {
			parseLine(line, index);
		}

		var hasRemainingOptions = false;
		for (instruction in currentNode.instructions) {
			if (instruction.opcode == OpCode.ADD_OPTIONS)
				hasRemainingOptions = true;

			if (instruction.opcode == OpCode.SHOW_OPTIONS)
				hasRemainingOptions = false;
		}

		if (hasRemainingOptions) {
			emit(currentNode, OpCode.SHOW_OPTIONS, []);
			emit(currentNode, OpCode.RUN_NODE, []);
		} else {
			emit(currentNode, OpCode.STOP, []);
		}

		currentNode = null;

		return node;
	}

	static inline var hashTag = "#(?'hashText'[^ \t\r\n#$<]+)";
	static inline var nodeId = "(?'nodeId'[a-zA-Z_][a-zA-Z0-9_.]*)";
	static inline var varId = "(?'var'\\$[a-zA-Z_][a-zA-Z0-9_]*)";
	static inline var funcId = "(?'funcId'[a-zA-Z_][a-zA-Z0-9_]*)";
	static inline var operationExpressionRegex = "([a-zA-Z0-9_\\$]+)";
	static inline var expressionRegex = "(.+)";
	static inline var commandStart = '<<';
	static inline var commandEnd = '>>';
	static inline var commandText = "(?'text'[^>{]+)";
	static inline var commandSet = "set";
	static inline var commandIf = "if";
	static inline var commandElseIf = "elseif";
	static inline var commandElse = "else";
	static inline var commandEndIf = "endif";
	static inline var commandCall = "call";
	static inline var optionsStart = "\\[\\[";
	static inline var optionsEnd = "\\]\\]";

	static var jumpRegex = new EReg('\\[\\[$nodeId\\]\\]', "i");
	static var optionsRegex = new EReg('\\[\\[(?\'optText\'[^\\]{|\\[]+)\\|$nodeId\\]\\]\\s*($hashTag)?', "i");
	static var setCommandRegex = new EReg('$commandStart$commandSet\\s+$expressionRegex$commandEnd', 'i');
	static var callCommandRegex = new EReg('$commandStart$commandCall\\s+$expressionRegex$commandEnd', 'i');
	static var customCommandRegex = new EReg('$commandStart$commandText$commandEnd', 'i');
	static var ifClauseRegex = new EReg('$commandStart$commandIf\\s+$expressionRegex$commandEnd', 'i');
	static var elseIfClauseRegex = new EReg('$commandStart$commandElseIf\\s+$expressionRegex$commandEnd', 'i');
	static var elseClauseRegex = new EReg('$commandStart$commandElse$commandEnd', 'i');
	static var endClauseRegex = new EReg('$commandStart$commandEndIf$commandEnd', 'i');

	static var isWhiteSpace = ~/^\s+$/;

	function parseLine(line:String, lineNumber:Int) {
		if (line.length <= 0 || StringTools.trim(line).substr(0, 2) == "//" || isWhiteSpace.match(line))
			return;

		if (jumpRegex.match(line)) {
			visitOptionJump(line, jumpRegex);
		} else if (optionsRegex.match(line)) {
			visitOptionLink(line, optionsRegex, lineNumber);
		} else if (setCommandRegex.match(line)) {
			vistSetCommand(line, setCommandRegex, lineNumber);
		} else if (callCommandRegex.match(line)) {
			vistCallCommand(line, callCommandRegex, lineNumber);
		} else if (ifClauseRegex.match(line)) {
			visitIfClause(ifClauseRegex);
		} else if (elseIfClauseRegex.match(line)) {
			visitIfElseClause(elseIfClauseRegex);
		} else if (elseClauseRegex.match(line)) {
			visitElseClause();
		} else if (endClauseRegex.match(line)) {
			visitEndIfClause();
		} else if (customCommandRegex.match(line)) {
			visitCommand(line, customCommandRegex, lineNumber);
		} else {
			visitLineStatement(line, lineNumber);
		}
	}

	function visitLineStatement(line:String, lineNumber:Int) {
		var formattedText = generateFormattedText(line);
		var hashTagReg = new EReg(hashTag, 'i');
		var hashtagText:String = null;
		if (hashTagReg.match(line)) {
			hashtagText = hashTagReg.matched(1);
			formattedText.composedString = StringTools.replace(formattedText.composedString, '#$hashtagText', '');
		}

		var stringId = registerString(StringTools.trim(formattedText.composedString), currentNode.name, getLineId(hashtagText), lineNumber, [hashtagText]);

		emit(currentNode, OpCode.RUN_LINE, [Operand.fromString(stringId), Operand.fromFloat(formattedText.expressionCount)]);
	}

	function visitOptionJump(line:String, matchedRegex:EReg) {
		var destination = StringTools.trim(matchedRegex.matched(1));
		emit(currentNode, OpCode.RUN_NODE, [Operand.fromString(destination)]);
	}

	function visitOptionLink(line:String, matchedRegex:EReg, lineNumber:Int) {
		var formattedText = generateFormattedText(matchedRegex.matched(1));

		var destination = matchedRegex.matched(2);
		var label = formattedText.composedString;

		var lineId = getLineId(matchedRegex.matched(4));
		var hashtagText = matchedRegex.matched(4);

		var stringId = registerString(label, currentNode.name, lineId, lineNumber, [hashtagText]);

		emit(currentNode, OpCode.ADD_OPTIONS, [
			Operand.fromString(stringId),
			Operand.fromString(destination),
			Operand.fromFloat(formattedText.expressionCount)
		]);
	}

	function vistSetCommand(line:String, match:EReg, lineNumber:Int) {
		// Adds the compiled expression value to the stack
		visitExpression(match.matched(1));
	}

	function vistCallCommand(line:String, match:EReg, lineNumber:Int) {
		// Adds the compiled expression value to the stack
		visitExpression(match.matched(1));
	}

	function visitCommand(line:String, match:EReg, lineNumber:Int) {
		// Adds the compiled expression value to the stack
		var formattedText = generateFormattedText(match.matched(1));

		switch (formattedText.composedString) {
			case "stop":
				emit(currentNode, OpCode.STOP, []);
			case _:
				emit(currentNode, OpCode.RUN_COMMAND, [
					Operand.fromString(formattedText.composedString),
					Operand.fromFloat(formattedText.expressionCount)
				]);
		}
	}

	function visitIfClause(regex:EReg) {
		var endOfIfStatmentLabel = registerLabel("endif");
		ifStatementEndLabels.push(endOfIfStatmentLabel);

		generateClause(ifStatementEndLabels.first(), regex.matched(1));
	}

	function visitIfElseClause(regex:EReg) {
		emit(currentNode, OpCode.JUMP_TO, [Operand.fromString(ifStatementEndLabels.first())]);
		if (!generateClauseLabels.isEmpty()) {
			currentNode.labels.set(generateClauseLabels.pop(), currentNode.instructions.length);
			emit(currentNode, OpCode.POP, []);
		}

		generateClause(ifStatementEndLabels.first(), regex.matched(1));
	}

	function visitElseClause() {
		emit(currentNode, OpCode.JUMP_TO, [Operand.fromString(ifStatementEndLabels.first())]);
		if (!generateClauseLabels.isEmpty()) {
			currentNode.labels.set(generateClauseLabels.pop(), currentNode.instructions.length);
			emit(currentNode, OpCode.POP, []);
		}

		generateClause(ifStatementEndLabels.first(), null);
	}

	function visitEndIfClause() {
		if (!generateClauseLabels.isEmpty()) {
			currentNode.labels.set(generateClauseLabels.pop(), currentNode.instructions.length);
			emit(currentNode, OpCode.POP, []);
		}

		currentNode.labels.set(ifStatementEndLabels.pop(), currentNode.instructions.length);
	}

	function generateClause(jumpLabel:String, expr:String) {
		var endOfCluase = registerLabel("skipclause");

		if (expr != null && StringTools.trim(expr).length > 0) {
			visitExpression(expr);
			emit(currentNode, OpCode.JUMP_IF_FALSE, [Operand.fromString(endOfCluase)]);
			generateClauseLabels.push(endOfCluase);
		}
	}

	function visitExpression(expression:String) {
		var exprs = new ExpressionParser(Scanner.scan(expression)).parse();
		var visitor = new ExpresionVisitor(this);

		visitor.resolve(exprs);
	}

	public function emit(node:Node, opCode:OpCode, operands:Array<Operand>) {
		var instruction = new Instruction();
		instruction.opcode = opCode;
		instruction.operands = operands;

		node.instructions.push(instruction);
	}

	function generateFormattedText(text:String):{composedString:String, expressionCount:Int} {
		var expressionCount = 0;
		var finalString = "";

		var index = 0;
		while (index < text.length) {
			var char = text.charAt(index);
			if (char == "{") {
				index++; // consume {
				var start = index;
				while (text.charAt(index) != "}") {
					index++;
				}
				visitExpression(text.substr(start, index - start));
				finalString += '{$expressionCount}';
				expressionCount += 1;
				index++; // consume }
			} else if (char == "[") {
				index++; // consume [
				var start = index;
				while (text.charAt(index) != "]") {
					index++;
				}
				var functions = text.substr(start, index - start).split(' ');
				visitExpression(functions[1].substr(1, functions[1].length - 2)); // variable. Remvoe {}
				finalString += '[${functions[0]} "{$expressionCount}"';
				for (kvp in functions.slice(2)) {
					finalString += ' $kvp';
				}
				finalString += ']';
				expressionCount += 1;
			} else {
				finalString += char;
			}

			index++;
		}

		return {
			composedString: StringTools.trim(finalString),
			expressionCount: expressionCount
		};
	}

	function getLineId(hashtagText:String):String {
		if (hashtagText == null || hashtagText.length <= 0)
			return null;

		if (StringTools.startsWith(hashtagText, "line:"))
			return hashtagText;

		return null;
	}

	function registerString(text:String, nodeName:String, lineId:String, lineNumber:Int, tags:Array<String>) {
		var lineIdUsed:String;
		var isImplicit:Bool;

		if (lineId == null) {
			lineIdUsed = '$fileName-$nodeName-$stringCount';

			stringCount++;

			containsImplicitStringTags = true;
			isImplicit = true;
		} else {
			lineIdUsed = lineId;
			isImplicit = false;
		}

		var theString = new StringInfo(text, fileName, nodeName, lineNumber, isImplicit, tags);

		stringTable.set(lineIdUsed, theString);

		return lineIdUsed;
	}

	function registerLabel(?commentary:String = null) {
		return 'L${labelCount++}$commentary';
	}
}

class ExpresionVisitor implements Expr.Visitor {
	var tokens = new Map<String, TokenType>();
	var compiler:Compiler;

	public function new(compiler:Compiler) {
		this.compiler = compiler;
		loadOperators();
	}

	function loadOperators() {
		tokens["is"] = TokenType.EqualTo;
		tokens["=="] = TokenType.EqualTo;
		tokens["eq"] = TokenType.EqualTo;
		tokens["!="] = TokenType.NotEqualTo;
		tokens["neq"] = TokenType.NotEqualTo;
		tokens["and"] = TokenType.And;
		tokens["&&"] = TokenType.And;
		tokens["or"] = TokenType.Or;
		tokens["||"] = TokenType.Or;
		tokens["xor"] = TokenType.Xor;
		tokens["^"] = TokenType.Xor;
		tokens["*"] = TokenType.Multiply;
		tokens["/"] = TokenType.Divide;
		tokens["%"] = TokenType.Modulo;
		tokens["+"] = TokenType.Add;
		tokens["-"] = TokenType.Minus;
		tokens["*="] = TokenType.Multiply;
		tokens["/="] = TokenType.Divide;
		tokens["%="] = TokenType.Modulo;
		tokens["+="] = TokenType.Add;
		tokens["-="] = TokenType.Minus;
		tokens["<="] = TokenType.LessThanOrEqualTo;
		tokens["lte"] = TokenType.LessThanOrEqualTo;
		tokens["<"] = TokenType.LessThan;
		tokens["lt"] = TokenType.LessThan;
		tokens[">="] = TokenType.GreaterThanOrEqualTo;
		tokens["gte"] = TokenType.GreaterThanOrEqualTo;
		tokens[">"] = TokenType.GreaterThan;
		tokens["gt"] = TokenType.GreaterThan;
	}

	public function resolve(exprs:Array<Expr>) {
		for (expr in exprs) {
			expr.accept(this);
		}
	}

	public function visitExpParens(expr:Expr.ExpParens):Dynamic {
		return expr.expression.accept(this);
	}

	public function visitExpAssign(expr:Expr.ExpAssign):Dynamic {
		expr.value.accept(this);

		compiler.emit(compiler.currentNode, OpCode.STORE_VARIABLE, [Operand.fromString(expr.name.lexeme)]);
		compiler.emit(compiler.currentNode, OpCode.POP, []);

		return 0;
	};

	public function visitExpNegative(expr:Expr.ExpNegative):Dynamic {
		expr.expression.accept(this);

		compiler.emit(compiler.currentNode, OpCode.PUSH_FLOAT, [Operand.fromFloat(1)]);
		compiler.emit(compiler.currentNode, OpCode.CALL_FUNC, [Operand.fromString(TokenType.UnaryMinus.getName())]);

		return 0;
	}

	public function visitExpNot(expr:Expr.ExpNot):Dynamic {
		expr.expression.accept(this);

		compiler.emit(compiler.currentNode, OpCode.PUSH_FLOAT, [Operand.fromFloat(1)]);
		compiler.emit(compiler.currentNode, OpCode.CALL_FUNC, [Operand.fromString(TokenType.Not.getName())]);

		return 0;
	}

	public function visitExpMultDivMod(expr:Expr.ExpMultDivMod):Dynamic {
		genericExpVisitor(expr.left, expr.right, expr.op);

		return 0;
	}

	public function visitExpAddSub(expr:Expr.ExpAddSub):Dynamic {
		genericExpVisitor(expr.left, expr.right, expr.op);

		return 0;
	}

	public function visitExpComparison(expr:Expr.ExpComparision):Dynamic {
		genericExpVisitor(expr.left, expr.right, expr.op);

		return 0;
	}

	public function visitExpEquality(expr:Expr.ExpEquality):Dynamic {
		genericExpVisitor(expr.left, expr.right, expr.op);

		return 0;
	}

	public function visitExpMultDivModEquals(expr:Expr.ExpMultDivModEquals):Dynamic {
		opEquals(expr.variableName.lexeme, expr.left, expr.op);

		return 0;
	}

	public function visitExpPlusMinusEquals(expr:Expr.ExpPlusMinusEquals):Dynamic {
		opEquals(expr.variableName.lexeme, expr.left, expr.op);

		return 0;
	}

	public function visitExpAndOrXor(expr:Expr.ExpAndOrXor):Dynamic {
		genericExpVisitor(expr.left, expr.right, expr.op);

		return 0;
	}

	public function visitExpValue(expr:Expr.ExpValue):Dynamic {
		switch (expr.value.type) {
			case src.hxyarn.compiler.Token.TokenType.VAR_ID:
				compiler.emit(compiler.currentNode, OpCode.PUSH_VARIABLE, [Operand.fromString(expr.value.lexeme)]);
			case src.hxyarn.compiler.Token.TokenType.NUMBER:
				var number = expr.value.literal;
				compiler.emit(compiler.currentNode, OpCode.PUSH_FLOAT, [Operand.fromFloat(number)]);
			case src.hxyarn.compiler.Token.TokenType.KEYWORD_TRUE:
				compiler.emit(compiler.currentNode, OpCode.PUSH_BOOL, [Operand.fromBool(true)]);
			case src.hxyarn.compiler.Token.TokenType.KEYWORD_FALSE:
				compiler.emit(compiler.currentNode, OpCode.PUSH_BOOL, [Operand.fromBool(false)]);
			case src.hxyarn.compiler.Token.TokenType.STRING:
				compiler.emit(compiler.currentNode, OpCode.PUSH_STRING, [Operand.fromString(expr.value.literal)]);
			case src.hxyarn.compiler.Token.TokenType.KEYWORD_NULL:
				compiler.emit(compiler.currentNode, OpCode.PUSH_NULL, []);
			case _:
				throw new Exception('Expresion value not implemented: ${expr.value.toString()}');
		}

		return 0;
	}

	public function visitExpFunc(expr:Expr.ExpFunc):Dynamic {
		for (arg in expr.arguments) {
			arg.accept(this);
		}

		compiler.emit(compiler.currentNode, OpCode.PUSH_FLOAT, [Operand.fromFloat(expr.arguments.length)]);
		compiler.emit(compiler.currentNode, OpCode.CALL_FUNC, [Operand.fromString(expr.callee)]);

		return 0;
	};

	function opEquals(varName:String, expr:Expr, op:Token) {
		compiler.emit(compiler.currentNode, OpCode.PUSH_VARIABLE, [Operand.fromString(varName)]);

		expr.accept(this);

		compiler.emit(compiler.currentNode, OpCode.PUSH_FLOAT, [Operand.fromFloat(2)]);
		compiler.emit(compiler.currentNode, OpCode.CALL_FUNC, [Operand.fromString(tokens[op.lexeme].getName())]);

		compiler.emit(compiler.currentNode, OpCode.STORE_VARIABLE, [Operand.fromString(varName)]);
		compiler.emit(compiler.currentNode, OpCode.POP, []);
	}

	function genericExpVisitor(left:Expr, right:Expr, op:src.hxyarn.compiler.Token) {
		left.accept(this);
		right.accept(this);

		compiler.emit(compiler.currentNode, OpCode.PUSH_FLOAT, [Operand.fromFloat(2)]);
		compiler.emit(compiler.currentNode, OpCode.CALL_FUNC, [Operand.fromString(tokens[op.lexeme].getName())]);
	}
}
