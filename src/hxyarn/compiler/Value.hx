package src.hxyarn.compiler;

import haxe.Exception;

interface ValueVisitor {
	function visitValueNumber(value:ValueNumber):Dynamic;
	function visitValueTrue(value:ValueTrue):Dynamic;
	function visitValueFalse(value:ValueFalse):Dynamic;
	function visitValueString(value:ValueString):Dynamic;
	function visitValueNull(value:ValueNull):Dynamic;
	function visitValueFunctionCall(value:ValueFunctionCall):Dynamic;
	function visitValueVariable(value:ValueVariable):Dynamic;
}

class Value {
	public function accept(visitor:ValueVisitor):Dynamic {
		throw new Exception("This should be overriden");
	};

	public var value(default, null):Token;
	public var literal(default, null):Dynamic;
}

class ValueNumber extends Value {
	public function new(value:Token, literal:Dynamic) {
		this.value = value;
		this.literal = literal;
	}

	override public function accept(visitor:ValueVisitor):Dynamic {
		return visitor.visitValueNumber(this);
	}
}

class ValueTrue extends Value {
	public function new(value:Token) {
		this.value = value;
		this.literal = true;
	}

	override public function accept(visitor:ValueVisitor):Dynamic {
		return visitor.visitValueTrue(this);
	}
}

class ValueFalse extends Value {
	public function new(value:Token) {
		this.value = value;
		this.literal = false;
	}

	override public function accept(visitor:ValueVisitor):Dynamic {
		return visitor.visitValueFalse(this);
	}
}

class ValueVariable extends Value {
	public function new(varId:Token, literal:Dynamic) {
		if (varId.type != VAR_ID)
			throw "Expected id";

		this.varId = varId;
		this.literal = literal;
	}

	override public function accept(visitor:ValueVisitor):Dynamic {
		return visitor.visitValueVariable(this);
	}

	public var varId(default, null):Token;
}

class ValueString extends Value {
	public function new(value:Token, literal:Dynamic) {
		this.value = value;
		this.literal = literal;
	}

	override public function accept(visitor:ValueVisitor):Dynamic {
		return visitor.visitValueString(this);
	}
}

class ValueNull extends Value {
	public function new(value:Token) {
		this.value = value;
		this.literal = null;
	}

	override public function accept(visitor:ValueVisitor):Dynamic {
		return visitor.visitValueNull(this);
	}
}

class ValueFunctionCall extends Value {
	public function new(functionId:Token, expressions:Array<Expr>) {
		if (functionId.type != FUNC_ID)
			throw "Expected id";

		this.functionId = functionId;
		this.expressions = expressions;
	}

	override public function accept(visitor:ValueVisitor):Dynamic {
		return visitor.visitValueFunctionCall(this);
	}

	public var functionId(default, null):Token;
	public var expressions(default, null):Array<Expr>;
}
