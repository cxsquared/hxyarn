package src.hxyarn.program.types;

import haxe.exceptions.NotImplementedException;
import src.hxyarn.program.types.IType.MethodCollection;

class TypeBase implements IType {
	public var name:String;
	public var methods:MethodCollection;
	public var description(get, null):String;

	private function new(methods:MethodCollection) {
		this.methods = new MethodCollection();

		if (methods == null)
			return;

		for (key => method in methods) {
			this.methods.set(key, method);
		}
	}

	public function parent():IType {
		throw new NotImplementedException();
	}

	public function defaultMethods():MethodCollection {
		return this.methods;
	}

	public function get_description():String {
		return "";
	}
}
