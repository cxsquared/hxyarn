package hxyarn.program.types;

import hxyarn.program.types.IType.MethodCollection;

class AnyType implements IType {
	public var name = "Any";

	public var methods:MethodCollection = null;

	public function new() {}

	public function get_description():String {
		return "Any type.";
	}

	public function parent():IType {
		return null;
	}

	public var description(get, null):String;

	public function defaultMethods():MethodCollection {
		return [];
	}
}
