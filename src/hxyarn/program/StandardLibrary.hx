package src.hxyarn.program;

import src.hxyarn.program.types.BuiltInTypes;
import src.hxyarn.program.VirtualMachine.TokenType;

class StandardLibrary extends Library {
	public function new() {
		super();

		this.registerFunction("string", 1, function(parameters:Array<Value>):Dynamic {
			return parameters[0].asString();
		}, BuiltInTypes.string);

		this.registerFunction("number", 1, function(parameters:Array<Value>):Dynamic {
			return parameters[0].asNumber();
		}, BuiltInTypes.number);

		this.registerFunction("number", 1, function(parameters:Array<Value>):Dynamic {
			return parameters[0].asBool();
		}, BuiltInTypes.boolean);

		this.registerMethods(BuiltInTypes.number);
		this.registerMethods(BuiltInTypes.string);
		this.registerMethods(BuiltInTypes.boolean);
	}
}
