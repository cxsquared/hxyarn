package src.hxyarn.compiler;

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
	var currentNode:Node;
	var rawTextNode = false;
	var program:Program;
	var fileName:String;
	var containsImplicitStringTags:Bool;
	var stringCount = 0;
	var stringTable = new Map<String, StringInfo>();
	var ifStatementEndLabels = new List<String>();
	var currentGenerateClauseLabel:String = null;
	var tokens = new Map<String, TokenType>();

	public function new(fileName:String) {
		program = new Program();
		this.fileName = fileName;
		this.loadOperators();
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

		currentNode.labels.set(registerLabel(), currentNode.instructions.length);

		node.name = obj.title;
		var tags = cast(obj.tags, String).split(",");
		node.tags = new Array<String>();
		for (tag in tags) {
			node.tags.push(StringTools.trim(tag));
		}

		var lines = cast(obj.body, String).split('\n');
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
	static inline var expressionRegex = "(.+)";
	static inline var commandStart = '<<';
	static inline var commandEnd = '>>';
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
	static var setCommandRegex = new EReg('$commandStart$commandSet\\s+$varId\\s+(to|=)\\s+$expressionRegex$commandEnd', 'i');
	static var ifClauseRegex = new EReg('$commandStart$commandIf\\s+$expressionRegex$commandEnd', 'i');
	static var elseIfClauseRegex = new EReg('$commandStart$commandElseIf\\s+$expressionRegex$commandEnd', 'i');
	static var elseClauseRegex = new EReg('$commandStart$commandElse$commandEnd', 'i');
	static var endClauseRegex = new EReg('$commandStart$commandEndIf$commandEnd', 'i');

	function parseLine(line:String, lineNumber:Int) {
		if (line.length <= 0)
			return;

		if (jumpRegex.match(line)) {
			visitOptionJump(line, jumpRegex);
		} else if (optionsRegex.match(line)) {
			visitOptionLink(line, optionsRegex, lineNumber);
		} else if (setCommandRegex.match(line)) {
			vistSetCommand(line, setCommandRegex, lineNumber);
		} else if (ifClauseRegex.match(line)) {
			visitIfClause(ifClauseRegex);
		} else if (elseIfClauseRegex.match(line)) {
			visitIfElseClause(elseIfClauseRegex);
		} else if (elseClauseRegex.match(line)) {
			visitElseClause();
		} else if (endClauseRegex.match(line)) {
			visitEndIfClause();
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
			formattedText.composedString = StringTools.replace(line, '#$hashtagText', '');
		}

		var stringId = registerString(formattedText.composedString, currentNode.name, getLineId(hashtagText), lineNumber, [hashtagText]);

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
		var varId = match.matched(1);
		var expr = match.matched(3);

		// Adds the compiled expression value to the stack
		visitExpression(expr);

		// store the variable and pop the value from the stack
		emit(currentNode, OpCode.STORE_VARIABLE, [Operand.fromString(varId)]);
		emit(currentNode, OpCode.POP, []);
	}

	function visitIfClause(regex:EReg) {
		var endOfIfStatmentLabel = registerLabel("endif");
		ifStatementEndLabels.push(endOfIfStatmentLabel);

		generateClause(ifStatementEndLabels.first(), regex.matched(1));
	}

	function visitIfElseClause(regex:EReg) {
		emit(currentNode, OpCode.JUMP_TO, [Operand.fromString(ifStatementEndLabels.first())]);
		if (currentGenerateClauseLabel != null) {
			currentNode.labels.set(currentGenerateClauseLabel, currentNode.instructions.length);
			emit(currentNode, OpCode.POP, []);
			currentGenerateClauseLabel = null;
		}

		generateClause(ifStatementEndLabels.first(), regex.matched(1));
	}

	function visitElseClause() {
		emit(currentNode, OpCode.JUMP_TO, [Operand.fromString(ifStatementEndLabels.first())]);
		if (currentGenerateClauseLabel != null) {
			currentNode.labels.set(currentGenerateClauseLabel, currentNode.instructions.length);
			emit(currentNode, OpCode.POP, []);
			currentGenerateClauseLabel = null;
		}

		generateClause(ifStatementEndLabels.first(), null);
	}

	function visitEndIfClause() {
		if (currentGenerateClauseLabel != null) {
			currentNode.labels.set(currentGenerateClauseLabel, currentNode.instructions.length);
			emit(currentNode, OpCode.POP, []);
			currentGenerateClauseLabel = null;
		}

		currentNode.labels.set(ifStatementEndLabels.pop(), currentNode.instructions.length);
	}

	function generateClause(jumpLabel:String, expr:String) {
		var endOfCluase = registerLabel("skipclause");

		if (expr != null && StringTools.trim(expr).length > 0) {
			visitExpression(expr);
			emit(currentNode, OpCode.JUMP_IF_FALSE, [Operand.fromString(endOfCluase)]);
			currentGenerateClauseLabel = endOfCluase;
		}
	}

	static inline var logicalNot = "(not|\\!)";
	static inline var logicalEquals = "(==|is|eq)";
	static inline var logicalNotEquals = "(!=|neq)";
	static inline var logicalLessThanEquals = "(<=|lte)";
	static inline var logicalGreaterThanEquals = "(>=|gte)";
	static inline var logicalLess = "(<|lt)";
	static inline var logicalGreater = "(>|gt)";

	static var exprParen = new EReg('(\\S*$expressionRegex\\S*)', 'i');
	static var exprEquals = new EReg('$expressionRegex\\s+($logicalEquals|$logicalNotEquals)\\s+$expressionRegex', 'i');
	static var exprNot = new EReg('($logicalNot)\\s+$expressionRegex', 'i');
	static var funcRegex = new EReg('$funcId\\($expressionRegex?\\s?(,$expressionRegex)*\\)', 'i');

	function visitExpression(expression:String) {
		if (exprEquals.match(expression)) {
			genericExpVisitor(exprEquals.matched(1), exprEquals.matched(2), exprEquals.matched(5));
		} else if (exprNot.match(expression)) {
			visitExpNot(exprNot.matched(3));
		} else if (funcRegex.match(expression)) {
			visitFunction(funcRegex);
		} else if (expression == 'true' || expression == 'false') {
			emit(currentNode, OpCode.PUSH_BOOL, [Operand.fromBool(expression == 'true' ? true : false)]);
		} else if (!Math.isNaN(Std.parseFloat(expression))) {
			emit(currentNode, OpCode.PUSH_FLOAT, [Operand.fromFloat(Std.parseFloat(expression))]);
		} else {
			emit(currentNode, OpCode.PUSH_STRING, [Operand.fromString(unescape(expression))]);
		}
	}

	function unescape(string:String):String {
		var newString = StringTools.replace(string, "\"", "");

		return newString;
	}

	function visitExpNot(expression:String) {
		visitExpression(expression);

		// number of arguments
		emit(currentNode, OpCode.PUSH_FLOAT, [Operand.fromFloat(1)]);
		emit(currentNode, OpCode.CALL_FUNC, [Operand.fromString(TokenType.Not.getName())]);
	}

	function visitFunction(funcRegex:EReg) {
		var functionName = funcRegex.matched(1);

		handleFunction(functionName, funcRegex.matched(2));
	}

	// https://stackabuse.com/regex-splitting-by-character-unless-in-quotes/
	static var splitEscapedRegex = ~/,(?=([^\\"]*\\"[^\\"]*\\")*[^\\"]*$)/;

	function handleFunction(functionName:String, arguments:String) {
		var splitExp = splitEscapedRegex.split(arguments);
		for (exp in splitExp) {
			visitExpression(exp);
		}

		emit(currentNode, OpCode.PUSH_FLOAT, [Operand.fromFloat(splitExp.length)]);
		emit(currentNode, OpCode.CALL_FUNC, [Operand.fromString(functionName)]);
	}

	function genericExpVisitor(left:String, op:String, right:String) {
		visitExpression(left);
		visitExpression(right);

		emit(currentNode, OpCode.PUSH_FLOAT, [Operand.fromFloat(2)]);
		emit(currentNode, OpCode.CALL_FUNC, [Operand.fromString(tokens[StringTools.trim(op)].getName())]);
	}

	function emit(node:Node, opCode:OpCode, operands:Array<Operand>) {
		var instruction = new Instruction();
		instruction.opcode = opCode;
		instruction.operands = operands;

		node.instructions.push(instruction);
	}

	function generateFormattedText(text:String):{composedString:String, expressionCount:Int} {
		// TODO check for expressions/commands

		return {
			composedString: StringTools.trim(text),
			expressionCount: 0
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

	function loadOperators() {
		tokens["is"] = TokenType.EqualTo;
		tokens["=="] = TokenType.EqualTo;
		tokens["eq"] = TokenType.EqualTo;
		tokens["!="] = TokenType.NotEqualTo;
		tokens["neq"] = TokenType.NotEqualTo;
	}
}
