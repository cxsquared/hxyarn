package src.hxyarn.compiler;

import haxe.Exception;

interface Visitor {
	function visitExpParens(expr:ExpParens):Dynamic;
	function visitExpNegative(expr:ExpNegative):Dynamic;
	function visitExpNot(expr:ExpNot):Dynamic;
	function visitExpMultDivMod(expr:ExpMultDivMod):Dynamic;
	function visitExpAddSub(expr:ExpAddSub):Dynamic;
	function visitExpComparison(expr:ExpComparision):Dynamic;
	function visitExpEquality(expr:ExpEquality):Dynamic;
	function visitExpMultDivModEquals(expr:ExpMultDivModEquals):Dynamic;
	function visitExpPlusMinusEquals(expr:ExpPlusMinusEquals):Dynamic;
	function visitExpAndOrXor(expr:ExpAndOrXor):Dynamic;
	function visitExpValue(expr:ExpValue):Dynamic;
}

class Expr {
	public function accept(visitor:Visitor):Dynamic {
		throw new Exception("This should be overriden");
	};
}

class ExpParens extends Expr {
	public function new(expression:Expr) {
		this.expression = expression;
	}

	override public function accept(visitor:Visitor) {
		return visitor.visitExpParens(this);
	}

	public var expression:Expr;
}

class ExpNegative extends Expr {
	public function new(expression:Expr) {
		this.expression = expression;
	}

	override public function accept(visitor:Visitor) {
		return visitor.visitExpNegative(this);
	}

	public var expression:Expr;
}

class ExpNot extends Expr {
	public function new(expression:Expr) {
		this.expression = expression;
	}

	override public function accept(visitor:Visitor) {
		return visitor.visitExpNot(this);
	}

	public var expression:Expr;
}

class ExpMultDivMod extends Expr {
	public function new(left:Expr, op:Token, right:Expr) {
		this.right = right;
		this.op = op;
		this.left = left;
	}

	override public function accept(visitor:Visitor) {
		return visitor.visitExpMultDivMod(this);
	}

	public var right:Expr;
	public var op:Token;
	public var left:Expr;
}

class ExpAddSub extends Expr {
	public function new(left:Expr, op:Token, right:Expr) {
		this.right = right;
		this.op = op;
		this.left = left;
	}

	override public function accept(visitor:Visitor) {
		return visitor.visitExpAddSub(this);
	}

	public var right:Expr;
	public var op:Token;
	public var left:Expr;
}

class ExpComparision extends Expr {
	public function new(left:Expr, op:Token, right:Expr) {
		this.right = right;
		this.op = op;
		this.left = left;
	}

	override public function accept(visitor:Visitor) {
		return visitor.visitExpComparison(this);
	}

	public var right:Expr;
	public var op:Token;
	public var left:Expr;
}

class ExpEquality extends Expr {
	public function new(left:Expr, op:Token, right:Expr) {
		this.right = right;
		this.op = op;
		this.left = left;
	}

	override public function accept(visitor:Visitor) {
		return visitor.visitExpEquality(this);
	}

	public var right:Expr;
	public var op:Token;
	public var left:Expr;
}

class ExpMultDivModEquals extends Expr {
	public function new(variableName:Token, op:Token, left:Expr) {
		this.variableName = variableName;
		this.op = op;
		this.left = left;
	}

	override public function accept(visitor:Visitor) {
		return visitor.visitExpMultDivModEquals(this);
	}

	public var variableName:Token;
	public var op:Token;
	public var left:Expr;
}

class ExpPlusMinusEquals extends Expr {
	public function new(variableName:Token, op:Token, left:Expr) {
		this.variableName = variableName;
		this.op = op;
		this.left = left;
	}

	override public function accept(visitor:Visitor) {
		return visitor.visitExpPlusMinusEquals(this);
	}

	public var variableName:Token;
	public var op:Token;
	public var left:Expr;
}

class ExpAndOrXor extends Expr {
	public function new(left:Expr, op:Token, right:Expr) {
		this.right = right;
		this.op = op;
		this.left = left;
	}

	override public function accept(visitor:Visitor) {
		return visitor.visitExpAndOrXor(this);
	}

	public var right:Expr;
	public var op:Token;
	public var left:Expr;
}

class ExpValue extends Expr {
	public function new(value:Token, literal:Dynamic) {
		this.value = value;
		this.literal = literal;
	}

	override public function accept(visitor:Visitor) {
		return visitor.visitExpValue(this);
	}

	public var value:Token;
	public var literal:Dynamic;
}
