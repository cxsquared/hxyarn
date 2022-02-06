package src.hxyarn.compiler;

import haxe.Exception;

interface ExprVisitor {
	function visitExprParens(expr:ExprParens):Dynamic;
	function visitExprAssign(expr:ExprAssign):Dynamic;
	function visitExprNegative(expr:ExprNegative):Dynamic;
	function visitExprNot(expr:ExprNot):Dynamic;
	function visitExprMultDivMod(expr:ExprMultDivMod):Dynamic;
	function visitExprAddSub(expr:ExprAddSub):Dynamic;
	function visitExprComparison(expr:ExprComparision):Dynamic;
	function visitExprEquality(expr:ExprEquality):Dynamic;
	function visitExprMultDivModEquals(expr:ExprMultDivModEquals):Dynamic;
	function visitExprPlusMinusEquals(expr:ExprPlusMinusEquals):Dynamic;
	function visitExprAndOrXor(expr:ExprAndOrXor):Dynamic;
	function visitExprValue(expr:ExprValue):Dynamic;
	function visitExprFunc(expr:ExprFunc):Dynamic;
}

class Expr {
	public function accept(visitor:ExprVisitor):Dynamic {
		throw new Exception("This should be overriden");
	};
}

class ExprAssign extends Expr {
	public function new(name:Token, value:Expr) {
		this.name = name;
		this.value = value;
	}

	override public function accept(visitor:ExprVisitor) {
		return visitor.visitExprAssign(this);
	}

	public var name:Token;
	public var value:Expr;
}

class ExprParens extends Expr {
	public function new(expression:Expr) {
		this.expression = expression;
	}

	override public function accept(visitor:ExprVisitor) {
		return visitor.visitExprParens(this);
	}

	public var expression:Expr;
}

class ExprNegative extends Expr {
	public function new(expression:Expr) {
		this.expression = expression;
	}

	override public function accept(visitor:ExprVisitor) {
		return visitor.visitExprNegative(this);
	}

	public var expression:Expr;
}

class ExprNot extends Expr {
	public function new(expression:Expr) {
		this.expression = expression;
	}

	override public function accept(visitor:ExprVisitor) {
		return visitor.visitExprNot(this);
	}

	public var expression:Expr;
}

class ExprMultDivMod extends Expr {
	public function new(left:Expr, op:Token, right:Expr) {
		this.right = right;
		this.op = op;
		this.left = left;
	}

	override public function accept(visitor:ExprVisitor) {
		return visitor.visitExprMultDivMod(this);
	}

	public var right:Expr;
	public var op:Token;
	public var left:Expr;
}

class ExprAddSub extends Expr {
	public function new(left:Expr, op:Token, right:Expr) {
		this.right = right;
		this.op = op;
		this.left = left;
	}

	override public function accept(visitor:ExprVisitor) {
		return visitor.visitExprAddSub(this);
	}

	public var right:Expr;
	public var op:Token;
	public var left:Expr;
}

class ExprComparision extends Expr {
	public function new(left:Expr, op:Token, right:Expr) {
		this.right = right;
		this.op = op;
		this.left = left;
	}

	override public function accept(visitor:ExprVisitor) {
		return visitor.visitExprComparison(this);
	}

	public var right:Expr;
	public var op:Token;
	public var left:Expr;
}

class ExprEquality extends Expr {
	public function new(left:Expr, op:Token, right:Expr) {
		this.right = right;
		this.op = op;
		this.left = left;
	}

	override public function accept(visitor:ExprVisitor) {
		return visitor.visitExprEquality(this);
	}

	public var right:Expr;
	public var op:Token;
	public var left:Expr;
}

class ExprMultDivModEquals extends Expr {
	public function new(variableName:Token, op:Token, left:Expr) {
		this.variableName = variableName;
		this.op = op;
		this.left = left;
	}

	override public function accept(visitor:ExprVisitor) {
		return visitor.visitExprMultDivModEquals(this);
	}

	public var variableName:Token;
	public var op:Token;
	public var left:Expr;
}

class ExprPlusMinusEquals extends Expr {
	public function new(variableName:Token, op:Token, left:Expr) {
		this.variableName = variableName;
		this.op = op;
		this.left = left;
	}

	override public function accept(visitor:ExprVisitor) {
		return visitor.visitExprPlusMinusEquals(this);
	}

	public var variableName:Token;
	public var op:Token;
	public var left:Expr;
}

class ExprAndOrXor extends Expr {
	public function new(left:Expr, op:Token, right:Expr) {
		this.right = right;
		this.op = op;
		this.left = left;
	}

	override public function accept(visitor:ExprVisitor) {
		return visitor.visitExprAndOrXor(this);
	}

	public var right:Expr;
	public var op:Token;
	public var left:Expr;
}

class ExprValue extends Expr {
	public function new(value:Token, literal:Dynamic) {
		this.value = value;
		this.literal = literal;
	}

	override public function accept(visitor:ExprVisitor) {
		return visitor.visitExprValue(this);
	}

	public var value:Token;
	public var literal:Dynamic;
}

class ExprFunc extends Expr {
	public function new(callee:String, paren:Token, arguments:Array<Expr>) {
		this.callee = callee;
		this.paren = paren;
		this.arguments = arguments;
	}

	override public function accept(visitor:ExprVisitor) {
		return visitor.visitExprFunc(this);
	}

	public var callee:String;
	public var paren:Token;
	public var arguments:Array<Expr>;
}
