package src.hxyarn;

import src.hxyarn.program.VirtualMachine.TokenType;

class StandardLibrary extends Library {
	public function new() {
		super();

		this.registerReturningFunction(TokenType.Add.getName(), 2, function(parameters:Array<Value>) {
			return parameters[0].add(parameters[1]);
		});

		this.registerReturningFunction(TokenType.Minus.getName(), 2, function(parameters:Array<Value>) {
			return parameters[0].sub(parameters[1]);
		});

		this.registerReturningFunction(TokenType.UnaryMinus.getName(), 1, function(parameters:Array<Value>) {
			return parameters[0].neg();
		});

		this.registerReturningFunction(TokenType.UnaryMinus.getName(), 1, function(parameters:Array<Value>) {
			return parameters[0].neg();
		});

		this.registerReturningFunction(TokenType.Divide.getName(), 2, function(parameters:Array<Value>) {
			return parameters[0].div(parameters[1]);
		});

		this.registerReturningFunction(TokenType.Multiply.getName(), 2, function(parameters:Array<Value>) {
			return parameters[0].mul(parameters[1]);
		});

		this.registerReturningFunction(TokenType.Modulo.getName(), 2, function(parameters:Array<Value>) {
			return parameters[0].mod(parameters[1]);
		});

		this.registerReturningFunction(TokenType.EqualTo.getName(), 2, function(parameters:Array<Value>) {
			return parameters[0].equals(parameters[1]);
		});

		this.registerReturningFunction(TokenType.NotEqualTo.getName(), 2, function(parameters:Array<Value>) {
			var equalTo = getFunction(TokenType.EqualTo.getName());

			return !equalTo.invoke(parameters).asBool();
		});

		this.registerReturningFunction(TokenType.GreaterThan.getName(), 2, function(parameters:Array<Value>) {
			return parameters[0].greaterThan(parameters[1]);
		});

		this.registerReturningFunction(TokenType.GreaterThanOrEqualTo.getName(), 2, function(parameters:Array<Value>) {
			return parameters[0].greatThanOrEqual(parameters[1]);
		});

		this.registerReturningFunction(TokenType.LessThan.getName(), 2, function(parameters:Array<Value>) {
			return parameters[0].lessThan(parameters[1]);
		});

		this.registerReturningFunction(TokenType.LessThanOrEqualTo.getName(), 2, function(parameters:Array<Value>) {
			return parameters[0].lessThanOrEqual(parameters[1]);
		});

		this.registerReturningFunction(TokenType.And.getName(), 2, function(parameters:Array<Value>) {
			return parameters[0].asBool() && parameters[1].asBool();
		});

		this.registerReturningFunction(TokenType.Or.getName(), 2, function(parameters:Array<Value>) {
			return parameters[0].asBool() || parameters[1].asBool();
		});

		this.registerReturningFunction(TokenType.Xor.getName(), 2, function(parameters:Array<Value>) {
			return Std.int(parameters[0].asNumber()) ^ Std.int(parameters[1].asNumber());
		});

		this.registerReturningFunction(TokenType.Not.getName(), 1, function(parameters:Array<Value>) {
			return !parameters[0].asBool();
		});
	}
}
