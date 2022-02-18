package hxyarn.program;

import haxe.display.Display.Package;
import haxe.Int32;

class Node {
	public var name:String;
	public var instructions = new Array<Instruction>();
	// A jump table, mapping the name of labels to positions
	// in the instruction list
	public var labels = new Map<String, Int32>();
	public var tags = new Array<String>();
	// the entry in the program's string table that contains the orginal
	// text of this node; null if this is not available
	public var sourceTextStringId:String;

	public function new() {}

	public function clone():Node {
		var newNode = new Node();
		newNode.name = this.name;
		newNode.instructions = this.instructions;
		newNode.labels = this.labels;
		newNode.tags = this.tags;
		newNode.sourceTextStringId = this.sourceTextStringId;

		return newNode;
	}
}
