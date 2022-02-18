package hxyarn.program;

import hxyarn.program.types.BuiltInTypes;

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

		this.registerFunction("random", 0, function(parameters:Array<Value>):Dynamic {
			return Math.random();
		}, BuiltInTypes.number);

		this.registerFunction("random_range", 2, function(parameters:Array<Value>):Dynamic {
			return Math.round(Math.random() * (parameters[1].asNumber() - parameters[0].asNumber()) + parameters[0].asNumber());
		}, BuiltInTypes.number);

		this.registerFunction("dice", 1, function(parameters:Array<Value>):Dynamic {
			var dice = Std.int(parameters[0].asNumber());

			return Math.floor(Math.random() * dice) + 1;
		}, BuiltInTypes.number);

		this.registerFunction("round", 1, function(parameters:Array<Value>):Dynamic {
			return Math.round(parameters[0].asNumber());
		}, BuiltInTypes.number);

		this.registerFunction("floor", 1, function(parameters:Array<Value>):Dynamic {
			return Math.floor(parameters[0].asNumber());
		}, BuiltInTypes.number);

		this.registerFunction("ciel", 1, function(parameters:Array<Value>):Dynamic {
			return Math.ceil(parameters[0].asNumber());
		}, BuiltInTypes.number);

		this.registerMethods(BuiltInTypes.number);
		this.registerMethods(BuiltInTypes.string);
		this.registerMethods(BuiltInTypes.boolean);
	}
}
