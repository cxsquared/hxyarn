package src.hxyarn.program.types;

import src.hxyarn.program.types.IType.MethodCollection;

class FunctionType implements IType {
	public var name = "Function";
	public var parent = BuiltInTypes.any;
	public var description(get, null):String;

	function get_description() {
		var parameterNames = new Array<String>();
		for (param in parameters) {
			if (param == null) {
				parameterNames.push("Undefined");
			} else {
				parameterNames.push(param.name);
			}
		}

		var returnTypeName = this.returnType != null ? this.returnType.name : "Undefined";

		return '(${parameterNames.join(", ")}) -> $returnTypeName';
	}

	public var parameters(default, null) = new Array<IType>();
	public var methods:MethodCollection = null;
	public var returnType:IType;

	public function new() {}
}
