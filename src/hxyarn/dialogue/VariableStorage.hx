package src.hxyarn.dialogue;

import src.hxyarn.program.types.BuiltInTypes;
import src.hxyarn.program.Value;

interface VariableStorage {
	public function setValue(variableName:String, value:Dynamic):Void;
	public function getValue(variableName:String):Value;
	public function clear():Void;
}

class MemoryVariableStore implements VariableStorage {
	var variables = new Map<String, Value>();

	public function new() {}

	public function setValue(variableName:String, value:Dynamic):Void {
		var castValue:Value;
		if (Std.isOfType(value, Value)) {
			castValue = cast(value, Value);
		} else if (Std.isOfType(value, String)) {
			castValue = new Value(value, BuiltInTypes.string);
		} else if (Std.isOfType(value, Float)) {
			castValue = new Value(value, BuiltInTypes.number);
		} else if (Std.isOfType(value, Int)) {
			castValue = new Value(value, BuiltInTypes.number);
		} else if (Std.isOfType(value, Bool)) {
			castValue = new Value(value, BuiltInTypes.boolean);
		} else {
			castValue = new Value(value, BuiltInTypes.any);
		}

		variables.set(variableName, castValue);
	}

	public function getValue(variableName:String):Value {
		var value = Value.NULL;
		if (variables.exists(variableName)) {
			value = variables.get(variableName);
		}

		return value;
	}

	public function clear() {
		variables.clear();
	}
}
