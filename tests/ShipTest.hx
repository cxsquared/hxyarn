package tests;

import src.hxyarn.program.types.BuiltInTypes;
import src.hxyarn.program.Value;
import tests.TestBase;

class ShipTest extends TestBase {
	var visited:Map<String, Bool>;

	public function new() {
		super('./yarns/Sally.json', null);

		visited = new Map<String, Bool>();

		dialogue.library.registerFunction("visited", 1, function(nodeName:Array<Value>):Bool {
			if (visited.exists(nodeName[0].asString()))
				return visited[nodeName[0].asString()];

			visited.set(nodeName[0].asString(), false);

			return false;
		}, BuiltInTypes.string);
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

	override public function nodeCompleteHandler(nodeName:String) {
		visited.set(nodeName, true);
	}
}
