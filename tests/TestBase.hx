package tests;

import src.hxyarn.Value;
import src.hxyarn.compiler.StringInfo;
import src.hxyarn.dialogue.Command;
import src.hxyarn.dialogue.OptionSet;
import src.hxyarn.dialogue.Line;
import src.hxyarn.dialogue.VariableStorage.MemoryVariableStore;
import src.hxyarn.dialogue.Dialogue;

class TestBase {
	var storage = new MemoryVariableStore();
	var dialogue:Dialogue;
	var stringTable:Map<String, StringInfo>;

	public function new() {
		dialogue = new Dialogue(new MemoryVariableStore());

		dialogue.logDebugMessage = this.logDebugMessage;
		dialogue.logErrorMessage = this.logErrorMessage;
		dialogue.lineHandler = this.lineHandler;
		dialogue.optionsHandler = this.optionsHandler;
		dialogue.commandHandler = this.commandHanlder;
		dialogue.nodeCompleteHandler = this.nodeCompleteHandler;
		dialogue.nodeStartHandler = this.nodeStartHandler;
		dialogue.dialogueCompleteHandler = this.dialogueCompleteHandler;

		dialogue.library.registerFunction("assert", 1, function(parameters:Array<Value>) {
			if (parameters[0].asBool() == false) {
				trace("--------ASSERT FAILED------");
			}
		});
	}

	public function getComposedTextForLine(line:Line):String {
		var text = stringTable[line.id].text;

		for (index => sub in line.substitutions) {
			text = StringTools.replace(text, '{$index}', sub);
		}

		return text;
	}

	function setUp(fileName:String) {}

	public function logDebugMessage(message:String):Void {
		trace('DEBUG: $message');
	}

	public function logErrorMessage(message:String):Void {
		trace('Error: $message');
	}

	public function lineHandler(line:Line):HandlerExecutionType {
		var text = getComposedTextForLine(line);
		trace(text);

		return HandlerExecutionType.ContinueExecution;
	}

	public function optionsHandler(options:OptionSet):HandlerExecutionType {
		for (option in options.options) {
			trace(' - ${getComposedTextForLine(option.line)}');
		}

		return HandlerExecutionType.ContinueExecution;
	}

	public function commandHanlder(command:Command):HandlerExecutionType {
		trace('Command: ${command.text}');

		return HandlerExecutionType.ContinueExecution;
	}

	public function nodeCompleteHandler(nodeName:String):HandlerExecutionType {
		return HandlerExecutionType.ContinueExecution;
	}

	public function nodeStartHandler(nodeName:String):HandlerExecutionType {
		return HandlerExecutionType.ContinueExecution;
	}

	public function dialogueCompleteHandler() {
	}
}
