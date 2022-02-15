package src.hxyarn.dialogue;

import src.hxyarn.dialogue.Line;

class Option {
	public function new(line:Line, id:Int, destinationNode:String, enabled:Bool) {
		this.line = line;
		this.id = id;
		this.destinationNode = destinationNode;
		this.enabled = enabled;
	}

	public var line(default, set):Line;

	function set_line(newLine) {
		return line = newLine;
	}

	public var id(default, set):Int;

	function set_id(newId) {
		return id = newId;
	}

	public var destinationNode(default, set):String;

	function set_destinationNode(newDestinationNode) {
		return destinationNode = newDestinationNode;
	}

	public var enabled:Bool;
}
