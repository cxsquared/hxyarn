package hxyarn.program;

import haxe.Exception;

class Program {
	public var name:String;
	public var nodes = new Map<String, Node>();

	public function new() {}

	public static function combine(programs:Array<Program>):Program {
		if (programs.length == 0) {
			throw new Exception("At least one program must be provided");
		}

		var output = new Program();

		for (otherProgram in programs) {
			for (nodeName => node in otherProgram.nodes) {
				if (output.nodes.exists(nodeName)) {
					throw new Exception('This node already contains a node named $nodeName');
				}

				output.nodes.set(nodeName, node.clone());
			}
		}

		return output;
	}

	public function getTagsForNode(nodeName:String):Array<String> {
		return nodes[nodeName].tags;
	}
}
