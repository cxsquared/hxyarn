package hxyarn.compiler;

import hxyarn.program.types.IType;
import hxyarn.compiler.Value.ValueVariable;
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
}

class Expr {
	public function accept(visitor:ExprVisitor):Dynamic {
		throw new Exception("This should be overriden");
	};

	public var children:Array<Dynamic>;
	public var type:IType;

	public function getChild<T>(c:Class<T>):T {
		if (children == null || children.length == 0)
			return null;

		for (child in children) {
			if (Std.isOfType(child, c))
				return child;
		}

		return null;
	}
}

class ExprAssign extends Expr {
	public function new(variable:ValueVariable, value:Expr) {
		this.variable = variable;
		this.value = value;

		children = [variable, value];
	}

	override public function accept(visitor:ExprVisitor) {
		return visitor.visitExprAssign(this);
	}

	public var variable:ValueVariable;
	public var value:Expr;
}

class ExprParens extends Expr {
	public function new(expression:Expr) {
		this.expression = expression;

		children = [expression];
	}

	override public function accept(visitor:ExprVisitor) {
		return visitor.visitExprParens(this);
	}

	public var expression:Expr;
}

class ExprNegative extends Expr {
	public function new(expression:Expr) {
		this.expression = expression;

		children = [expression];
	}

	override public function accept(visitor:ExprVisitor) {
		return visitor.visitExprNegative(this);
	}

	public var expression:Expr;
}

class ExprNot extends Expr {
	public function new(expression:Expr) {
		this.expression = expression;

		children = [expression];
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

		children = [left, right, op];
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

		children = [left, right, op];
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

		children = [left, right, op];
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

		children = [left, right, op];
	}

	override public function accept(visitor:ExprVisitor) {
		return visitor.visitExprEquality(this);
	}

	public var right:Expr;
	public var op:Token;
	public var left:Expr;
}

class ExprMultDivModEquals extends Expr {
	public function new(variable:ValueVariable, op:Token, left:Expr) {
		this.variable = variable;
		this.op = op;
		this.left = left;

		children = [variable, left, op];
	}

	override public function accept(visitor:ExprVisitor) {
		return visitor.visitExprMultDivModEquals(this);
	}

	public var variable:ValueVariable;
	public var op:Token;
	public var left:Expr;
}

class ExprPlusMinusEquals extends Expr {
	public function new(variable:ValueVariable, op:Token, left:Expr) {
		this.variable = variable;
		this.op = op;
		this.left = left;

		children = [variable, left, op];
	}

	override public function accept(visitor:ExprVisitor) {
		return visitor.visitExprPlusMinusEquals(this);
	}

	public var variable:ValueVariable;
	public var op:Token;
	public var left:Expr;
}

class ExprAndOrXor extends Expr {
	public function new(left:Expr, op:Token, right:Expr) {
		this.right = right;
		this.op = op;
		this.left = left;

		children = [left, right, op];
	}

	override public function accept(visitor:ExprVisitor) {
		return visitor.visitExprAndOrXor(this);
	}

	public var right:Expr;
	public var op:Token;
	public var left:Expr;
}

class ExprValue extends Expr {
	public function new(value:Value) {
		this.value = value;

		children = [value];
	}

	override public function accept(visitor:ExprVisitor) {
		return visitor.visitExprValue(this);
	}

	public var value:Value;
	public var literal:Dynamic;
}
