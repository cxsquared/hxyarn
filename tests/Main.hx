package tests;

import src.hxyarn.Value;
import src.hxyarn.dialogue.Command;
import src.hxyarn.dialogue.OptionSet;
import src.hxyarn.dialogue.Line;
import src.hxyarn.dialogue.VariableStorage.MemoryVariableStore;
import src.hxyarn.dialogue.Dialogue;
import src.hxyarn.compiler.Compiler;

class Main {
	public static function main() {
		var compiler = Compiler.compileFile('./yarns/Sally.json');
		var visited = new Map<String, Bool>();

		var d = new Dialogue(new MemoryVariableStore());
		d.addProgram(compiler.program);
		d.logDebugMessage = function(message:String) {
			trace('DEBUG: $message');
		}

		d.logErrorMessage = function(message:String) {
			trace('ERROR: $message');
		}

		d.lineHandler = function(line:Line):HandlerExecutionType {
			trace(compiler.stringTable.get(line.id).text);

			return HandlerExecutionType.ContinueExecution;
		}

		d.optionsHandler = function(options:OptionSet):HandlerExecutionType {
			for (option in options.options) {
				trace(compiler.stringTable.get(option.line.id).text);
			}

			return HandlerExecutionType.ContinueExecution;
		}

		d.commandHandler = function(command:Command):HandlerExecutionType {
			trace(command.text);

			return HandlerExecutionType.ContinueExecution;
		}

		d.nodeCompleteHandler = function(nodeName:String):HandlerExecutionType {
			trace('Completed $nodeName');
			visited.set(nodeName, true);

			return HandlerExecutionType.ContinueExecution;
		}

		d.nodeStartHandler = function(nodeName:String):HandlerExecutionType {
			trace('Started $nodeName');

			return HandlerExecutionType.ContinueExecution;
		}

		d.dialogueCompleteHandler = function() {
			trace('Done');
		}

		d.library.registerReturningFunction("visited", 1, function(nodeName:Array<Value>):Bool {
			if (visited.exists(nodeName[0].asString()))
				return visited[nodeName[0].asString()];

			visited.set(nodeName[0].asString(), false);

			return false;
		});

		d.setNode("Sally");
		d.resume();
		d.setSelectedOption(0);
		d.resume();
		d.setNode("Sally");
		d.resume();
		d.setSelectedOption(0);
		d.resume();
		d.setNode("Sally");
		d.resume();
		d.setSelectedOption(0);
	}
}
