package src.hxyarn.dialogue;

import src.hxyarn.program.StandardLibrary;
import src.hxyarn.program.Library;
import src.hxyarn.dialogue.CLDR.PluralCase;
import src.hxyarn.dialogue.DialogueExcpetion.DialogueException;
import sys.io.File;
import src.hxyarn.program.Library.FunctionInfo;
import haxe.Exception;
import src.hxyarn.program.VirtualMachine;
import src.hxyarn.dialogue.OptionSet;
import src.hxyarn.program.Program;

typedef Logger = String->Void;
typedef LineHandler = Line->HandlerExecutionType;
typedef OptionsHandler = OptionSet->HandlerExecutionType;
typedef CommandHandler = Command->HandlerExecutionType;
typedef NodeCompleteHandler = String->HandlerExecutionType;
typedef NodeStartHanlder = String->HandlerExecutionType;
typedef DialogueCompleteHandler = Void->Void;

enum HandlerExecutionType {
	PauseExecution;
	ContinueExecution;
}

class Dialogue {
	public var variableStorage:VariableStorage;

	public var logDebugMessage:Logger;
	public var logErrorMessage:Logger;

	public static inline var DEFAULT_START = "Start";

	static inline var formatFunctionValuePlaceHolder = "<VALUE PLACEHOLDER>";

	var program(default, set):Program;

	function set_program(newProgram) {
		vm.program = newProgram;
		vm.resetState();

		return program = newProgram;
	}

	var vm:VirtualMachine;

	public function isActive() {
		return vm.executionState != ExecutionState.Stopped;
	}

	public var lineHandler(get, set):LineHandler;
	public var optionsHandler(get, set):OptionsHandler;
	public var commandHandler(get, set):CommandHandler;
	public var nodeStartHandler(get, set):NodeStartHanlder;
	public var nodeCompleteHandler(get, set):NodeCompleteHandler;
	public var dialogueCompleteHandler(get, set):DialogueCompleteHandler;

	public function get_lineHandler() {
		return vm.lineHandler;
	}

	public function set_lineHandler(newLineHandler) {
		return vm.lineHandler = newLineHandler;
	}

	public function get_optionsHandler() {
		return vm.optionsHandler;
	}

	public function set_optionsHandler(newOptionsHandler) {
		return vm.optionsHandler = newOptionsHandler;
	}

	public function get_commandHandler() {
		return vm.commandHandler;
	}

	public function set_commandHandler(newCommandHandler) {
		return vm.commandHandler = newCommandHandler;
	}

	public function get_nodeStartHandler() {
		return vm.nodeStartHandler;
	}

	public function set_nodeStartHandler(newNodeStartHandler) {
		return vm.nodeStartHandler = newNodeStartHandler;
	}

	public function get_nodeCompleteHandler() {
		return vm.nodeCompleteHandler;
	}

	public function set_nodeCompleteHandler(newNodeCompleteHandler) {
		return vm.nodeCompleteHandler = newNodeCompleteHandler;
	}

	public function get_dialogueCompleteHandler() {
		return vm.dialogueCompleteHandler;
	}

	public function set_dialogueCompleteHandler(newDialogueCopmleteHandler) {
		return vm.dialogueCompleteHandler = newDialogueCopmleteHandler;
	}

	public var library(default, set):Library;

	function set_library(newLibrary) {
		return library = newLibrary;
	}

	public function new(variableStorage:VariableStorage) {
		if (variableStorage == null)
			throw new DialogueException("Must provide a VariableStorage for a Dialogue");

		this.variableStorage = variableStorage;
		library = new Library();

		this.vm = new VirtualMachine(this);

		library.importLibrary(new StandardLibrary());
	}

	public function setProgram(program:Program) {
		this.program = program;
	}

	public function addProgram(program:Program) {
		if (this.program == null) {
			setProgram(program);
			return;
		}

		this.program = Program.combine([this.program, program]);
	}

	public function setNode(?startNode:String = DEFAULT_START) {
		vm.setNode(startNode);
	}

	public function setSelectedOption(selectedOptionId:Int) {
		vm.setSelectedOption(selectedOptionId);
	}

	public function resume() {
		if (vm.executionState == ExecutionState.Running)
			return;

		vm.contiune();
	}

	public function stop() {
		if (vm != null)
			vm.stop();
	}

	public var allNodes(get, null):Iterator<String>;

	public function get_allNodes() {
		return program.nodes.keys();
	}

	public var currentNode(get, null):String;

	public function get_currentNode() {
		if (vm == null)
			return null;

		return vm.currentNodeName();
	}

	public function getStringIdForNode(nodeName:String) {
		if (Lambda.count(program.nodes) == 0) {
			logErrorMessage("No nodes are loaded!");
			return null;
		}

		if (program.nodes.exists(nodeName))
			return 'line: $nodeName';

		logErrorMessage('No node named $nodeName');
		return null;
	}

	public function getTagsForNode(nodeName) {
		if (Lambda.count(program.nodes) == 0) {
			logErrorMessage("No nodes are loaded!");
			return null;
		}

		if (program.nodes.exists(nodeName))
			return program.getTagsForNode(nodeName);

		logErrorMessage('No node named $nodeName');
		return null;
	}

	public function unloadAll() {
		program = null;
	}

	public function nodeExists(nodeName:String):Bool {
		if (program == null) {
			logErrorMessage("Tried to call nodeExists, but no nodes have been compiled!");
			return false;
		}

		if (program.nodes == null || Lambda.count(program.nodes) == 0) {
			logDebugMessage("Called nodeExists, but there are zero nodes. This may be an error.");
			return false;
		}

		return program.nodes.exists(nodeName);
	}

	// TODO
	public function analyse() {}

	public static function expandFormatFunctions(input:String, localeCode:String) {
		var parsedFunction = parseFormatFunctions(input, localeCode);

		for (i in 0...parsedFunction.parsedFunctions.length) {
			var pFunc = parsedFunction.parsedFunctions[i];

			if (pFunc.functionName == "select") {
				var replacement = "";
				if (pFunc.data.exists(pFunc.value)) {
					replacement = pFunc.data.get(pFunc.value);
				} else {
					replacement = '<no replacement for ${pFunc.value}>';
				}

				replacement = StringTools.replace(replacement, formatFunctionValuePlaceHolder, pFunc.value);

				parsedFunction.lineWithReplacements = StringTools.replace(parsedFunction.lineWithReplacements, '{$i}', replacement);
			} else {
				var value = Std.parseFloat(pFunc.value);
				if (Math.isNaN(value))
					throw new Exception('Error while pluralizing line "$input": "${pFunc.value}" is not a number"');

				var pluralCase:PluralCase;

				switch (pFunc.functionName) {
					case "plural":
						pluralCase = CLDR.getCardinalPluralCase(localeCode, value);
					case "ordinal":
						pluralCase = CLDR.getOrdinalPluralCase(localeCode, value);
					case _:
						throw new Exception('Unknown formatting function "${pFunc.functionName}" in line "$input"');
				}

				var replacement = "";
				if (pFunc.data.exists(pluralCase.getName().toLowerCase())) {
					replacement = pFunc.data.get(pluralCase.getName().toLowerCase());
				} else {
					replacement = '<no replacement for ${pFunc.value}>';
				}

				replacement = StringTools.replace(replacement, formatFunctionValuePlaceHolder, pFunc.value);

				parsedFunction.lineWithReplacements = StringTools.replace(parsedFunction.lineWithReplacements, '{$i}', replacement);
			}
		}

		return parsedFunction.lineWithReplacements;
	}

	static function parseFormatFunctions(input:String, localeCode:String):{lineWithReplacements:String, parsedFunctions:Array<ParsedFormatFunction>} {
		var returnedLine = "";
		var returnedFunctions = new Array<ParsedFormatFunction>();

		var i = 0;
		while (i < input.length) {
			var c = input.charAt(i);

			if (c != '[') {
				if (c != ']')
					returnedLine += c;
				i++;
			} else {
				var pFunc = new ParsedFormatFunction();
				i += 1; // consume [

				var name = "";
				while (input.charAt(i) != " ") {
					name += input.charAt(i);
					i++;
				}
				pFunc.functionName = name;

				switch (pFunc.functionName) {
					case "select":
					case "plural":
					case "ordinal":
					case _:
						throw new Exception('Invalid formatting function ${pFunc.functionName} in line "$input"');
				}
				i += 1; // consume whitespace

				if (input.charAt(i) != "\"")
					throw new Exception('Expecting variable start in line "$input"');

				i += 1; // consume "

				var variable = "";
				while (input.charAt(i) != "\"") {
					variable += input.charAt(i);
					i++;
				}
				pFunc.value = variable;
				i += 2; // consume " and whitespace

				var key = "";
				var value = "";
				var buildingKey = true;
				while (input.charAt(i) != ']' && i < input.length) {
					var c = input.charAt(i);
					if (c == "=") {
						i += 2;
						buildingKey = false;
						continue;
					} else if (c == "\"") {
						buildingKey = true;

						if (pFunc.data.exists(key))
							throw new Exception('Duplicate value "$key" in format function inside line "$input"');

						pFunc.data.set(key, value); // remove "" around value
						key = "";
						value = "";
						if (input.charAt(i + 1) == ']') {
							i++;
						} else {
							i += 2;
						}
						continue;
					} else if (c == " " && buildingKey) {
						i++;
						continue;
					} else if (c == "%" && !buildingKey) {
						value += formatFunctionValuePlaceHolder;
						i++;
						continue;
					}

					if (buildingKey) {
						key += c;
					} else {
						value += c;
					}

					i++;
				}

				returnedFunctions.push(pFunc);

				returnedLine += '{${returnedFunctions.length - 1}}';
			}
		}

		return {lineWithReplacements: returnedLine, parsedFunctions: returnedFunctions};
	}
}
