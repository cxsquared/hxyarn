package src.hxyarn.compiler;

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
	static inline var expression = "(?'expr'\\S+)";
	static inline var commandStart = '<<';
	static inline var commandEnd = '>>';
	static inline var commandSet = "set";
	static inline var optionsStart = "\\[\\[";
	static inline var optionsEnd = "\\]\\]";

	static var jumpRegex = new EReg('\\[\\[$nodeId\\]\\]', "i");
	static var optionsRegex = new EReg('\\[\\[(?\'optText\'[^\\]{|\\[]+)\\|$nodeId\\]\\]\\s*($hashTag)?', "i");
	static var setCommandRegex = new EReg('$commandStart$commandSet\\s+$varId\\s+(to|=)\\s+$expression\\s+$commandEnd', 'i');

	function parseLine(line:String, lineNumber:Int) {
		if (jumpRegex.match(line)) {
			visitOptionJump(line, jumpRegex);
		} else if (optionsRegex.match(line)) {
			visitOptionLink(line, optionsRegex, lineNumber);
		} else if (setCommandRegex.match(line)) {
			vistSetCommand(line, setCommandRegex, lineNumber);
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

	function visitExpression(expression:String) {
		if (expression == 'true' || expression == 'false') {
			emit(currentNode, OpCode.PUSH_BOOL, [Operand.fromBool(expression == 'true' ? true : false)]);
		} else if (!Math.isNaN(Std.parseFloat(expression))) {
			emit(currentNode, OpCode.PUSH_FLOAT, [Operand.fromFloat(Std.parseFloat(expression))]);
		} else {
			emit(currentNode, OpCode.PUSH_STRING, [Operand.fromString(expression)]);
		}
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
}
