package tests;

import hxyarn.compiler.Compiler;
import haxe.Exception;
import tests.TestPlan;
import hxyarn.program.Value;
import hxyarn.dialogue.Command;
import hxyarn.dialogue.OptionSet;
import hxyarn.dialogue.Line;
import hxyarn.dialogue.VariableStorage.MemoryVariableStore;
import hxyarn.dialogue.Dialogue;
import hxyarn.dialogue.StringInfo;

class TestBase {
	var storage = new MemoryVariableStore();
	var dialogue:Dialogue;
	var stringTable:Map<String, StringInfo>;
	var testPlan:TestPlan;

	public function new(yarnFile:String, ?testPlanFile:String = null) {
		dialogue = new Dialogue(new MemoryVariableStore());

		dialogue.logDebugMessage = this.logDebugMessage;
		dialogue.logErrorMessage = this.logErrorMessage;
		dialogue.lineHandler = this.lineHandler;
		dialogue.optionsHandler = this.optionsHandler;
		dialogue.commandHandler = this.commandHandler;
		dialogue.nodeCompleteHandler = this.nodeCompleteHandler;
		dialogue.nodeStartHandler = this.nodeStartHandler;
		dialogue.dialogueCompleteHandler = this.dialogueCompleteHandler;

		dialogue.library.registerFunction("assert", 1, function(parameters:Array<Value>) {
			if (parameters[0].asBool() == false) {
				logErrorMessage("--------ASSERT FAILED------");
			}

			return null;
		});

		if (testPlanFile != null && StringTools.trim(testPlanFile).length > 0)
			testPlan = new TestPlan(testPlanFile);

		var compiler = Compiler.compileFile(yarnFile);
		stringTable = compiler.stringTable;

		dialogue.addProgram(compiler.program);
	}

	public function start() {
		dialogue.setNode("Start");

		do {
			dialogue.resume();
		} while (dialogue.isActive());
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
		trace('Line: $text');

		if (testPlan != null) {
			testPlan.next();

			if (testPlan.nextExpectedType == StepType.Line) {
				assertString(testPlan.nextExpectedValue, text);
			} else {
				throw new Exception('Recieved line $text, but was expected a ${testPlan.nextExpectedType.getName()}');
			}
		}

		return HandlerExecutionType.ContinueExecution;
	}

	public function optionsHandler(options:OptionSet) {
		var optionCount = options.options.length;
		var optionText = new Array<String>();

		trace("Options:");
		for (option in options.options) {
			var text = getComposedTextForLine(option.line);
			optionText.push(text);
			trace(' - $text');
		}

		if (testPlan != null) {
			testPlan.next();

			if (testPlan.nextExpectedType != StepType.Select) {
				throw new Exception('Recieved $optionCount options, but wasn\'t expecting them (was expecting ${testPlan.nextExpectedType.getName()})');
			}

			assertInt(testPlan.nextExpectedOptions.length, optionCount);

			for (index => option in options.options) {
				assertString(testPlan.nextExpectedOptions[index].line, optionText[index]);
				assertBool(testPlan.nextExpectedOptions[index].enabled, option.enabled);
			}

			if (testPlan.nextOptionToSelect > 0) {
				dialogue.setSelectedOption(testPlan.nextOptionToSelect - 1);
			} else {
				dialogue.setSelectedOption(0);
			}
		}
	}

	public function getComposedTextForLine(line:Line):String {
		var substitutedText = Dialogue.expandSubstitutions(stringTable[line.id].text, line.substitutions);

		var markup = dialogue.parseMarkup(substitutedText);

		return markup.text;
	}

	public function commandHandler(command:Command) {
		trace('Command: ${command.text}');

		if (testPlan != null) {
			testPlan.next();
			if (testPlan.nextExpectedType != StepType.Command) {
				throw new Exception('Recieved command ${command.text}, but wasn\'t expecting to select one (was expecting ${testPlan.nextExpectedType.getName()})');
			} else {
				assertString(testPlan.nextExpectedValue, command.text);
			}
		}
	}

	public function nodeCompleteHandler(nodeName:String) {}

	public function nodeStartHandler(nodeName:String) {}

	public function dialogueCompleteHandler() {
		if (testPlan != null) {
			testPlan.next();

			if (testPlan.nextExpectedType != StepType.Stop) {
				throw new Exception('Stopped dialogue,  but wasn\'t expecting to select one (was expecting ${testPlan.nextExpectedType.getName()})');
			}

			logDebugMessage('${testPlan.path} test passed!');
		}
	}

	function assertString(expected:String, actual:String) {
		if (expected != actual)
			throw new Exception('Expected: "$expected", but got "$actual"');
	}

	function assertBool(expected:Bool, actual:Bool) {
		if (expected != actual)
			throw new Exception('Expected: "$expected", but got "$actual"');
	}

	function assertInt(expected:Int, actual:Int) {
		if (expected != actual)
			throw new Exception('Expected: "$expected", but got "$actual"');
	}
}
