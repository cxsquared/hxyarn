package hxyarn.program;

import hxyarn.program.types.BuiltInTypes;
import haxe.ds.GenericStack;
import hxyarn.dialogue.Line;

typedef LineKeyValuePair = {line:Line, value:String, enabled:Bool};

class State {
	public var currentNodeName:String;
	public var programCounter:Int;
	public var currentOptions = new Array<LineKeyValuePair>();

	var stack = new GenericStack<Value>();

	public function new() {}

	public function PushValue(value:Dynamic) {
		if (Std.isOfType(value, Value)) {
			stack.add(cast(value, Value));
		} else if (Std.isOfType(value, String)) {
			stack.add(new Value(value, BuiltInTypes.string));
		} else if (Std.isOfType(value, Float)) {
			stack.add(new Value(value, BuiltInTypes.number));
		} else if (Std.isOfType(value, Int)) {
			stack.add(new Value(value, BuiltInTypes.number));
		} else if (Std.isOfType(value, Bool)) {
			stack.add(new Value(value, BuiltInTypes.boolean));
		} else {
			stack.add(new Value(value, BuiltInTypes.any));
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
