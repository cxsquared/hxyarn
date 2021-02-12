package src.hxyarn.compiler;

import src.hxyarn.program.Node;
import sys.io.File;
import haxe.Json;
import src.hxyarn.program.Program;

class Compiler {
	public static function compileFromJson(path:String):Program {
		var json = Json.parse(File.getContent(path));

		return new Program();
	}

	static function parseNode(obj:Dynamic):Node {
		var node = new Node();

		node.name = obj.title;
		var tags = cast(obj.tags, String).split(",");
		node.tags = new Array<String>();
		for (tag in tags) {
			node.tags.push(StringTools.trim(tag));
		}

		var lines = cast(obj.body, String).split('\n');
		for (line in lines) {}

		return node;
	}

	static function parseLine()
		public static function registerLabel()
}
