package src.hxyarn.program.types;

import src.hxyarn.program.types.IType.MethodCollection;

class AnyType implements IType {
	public var name = "Any";

	public var parent:IType = null;

	public var methods:MethodCollection = null;

	public function new() {}

	public function get_description():String {
		return "Any type.";
	}

	public var description(get, null):String;

	public function defaultMethods():MethodCollection {
		return [];
	}
}
