package src.hxyarn.program;

import haxe.ds.GenericStack;
import src.hxyarn.dialogue.Line;

typedef LineKeyValuePair = {line:Line, value:String}

class State {
	public var currentNodeName:String;
	public var programCounter:Int;
	public var currentOptions = new Array<LineKeyValuePair>();

	var stack = new GenericStack<Value>();

	public function new() {}

	public function PushValue(value:Dynamic) {
		if (Std.isOfType(value, Value)) {
			stack.add(cast(value, Value));
		} else {
			stack.add(new Value(value));
		}
	}

	public function PopValue():Value {
		return stack.pop();
	}

	public function PeekValue():Value {
		return stack.head.elt;
	}

	public function ClearStack() {
		stack = new GenericStack<Value>();
	}

	public function clearOptions() {
		currentOptions = new Array<LineKeyValuePair>();
	}
}
