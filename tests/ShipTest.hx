package tests;

import src.hxyarn.dialogue.Dialogue.HandlerExecutionType;
import src.hxyarn.Value;
import src.hxyarn.compiler.Compiler;
import tests.TestBase;

class ShipTest extends TestBase {
	var visited:Map<String, Bool>;

	public function new() {
		super('./yarns/Sally.json', null);

		visited = new Map<String, Bool>();

		dialogue.library.registerReturningFunction("visited", 1, function(nodeName:Array<Value>):Bool {
			if (visited.exists(nodeName[0].asString()))
				return visited[nodeName[0].asString()];

			visited.set(nodeName[0].asString(), false);

			return false;
		});
	}

	override public function start() {
		dialogue.setNode("Sally");
		dialogue.resume();
		dialogue.setSelectedOption(0);
		dialogue.resume();
		dialogue.setNode("Sally");
		dialogue.resume();
		dialogue.setSelectedOption(0);
		dialogue.resume();
		dialogue.setNode("Sally");
		dialogue.resume();
		dialogue.setSelectedOption(0);
	}

	override public function nodeCompleteHandler(nodeName:String):HandlerExecutionType {
		visited.set(nodeName, true);

		return super.nodeCompleteHandler(nodeName);
	}
}
