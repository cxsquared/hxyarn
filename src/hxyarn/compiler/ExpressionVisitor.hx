package src.hxyarn.compiler;

import src.hxyarn.program.Operand;
import src.hxyarn.program.Instruction.OpCode;
import src.hxyarn.program.VirtualMachine.TokenType;

class ExpresionVisitor implements Expr.ExprVisitor {
	var tokens = new Map<String, TokenType>();
	var compiler:Compiler;

	public function new(compiler:Compiler) {
		this.compiler = compiler;
		loadOperators();
	}

	function loadOperators() {
		tokens["is"] = TokenType.EqualTo;
		tokens["=="] = TokenType.EqualTo;
		tokens["eq"] = TokenType.EqualTo;
		tokens["!="] = TokenType.NotEqualTo;
		tokens["neq"] = TokenType.NotEqualTo;
		tokens["and"] = TokenType.And;
		tokens["&&"] = TokenType.And;
		tokens["or"] = TokenType.Or;
		tokens["||"] = TokenType.Or;
		tokens["xor"] = TokenType.Xor;
		tokens["^"] = TokenType.Xor;
		tokens["*"] = TokenType.Multiply;
		tokens["/"] = TokenType.Divide;
		tokens["%"] = TokenType.Modulo;
		tokens["+"] = TokenType.Add;
		tokens["-"] = TokenType.Minus;
		tokens["*="] = TokenType.Multiply;
		tokens["/="] = TokenType.Divide;
		tokens["%="] = TokenType.Modulo;
		tokens["+="] = TokenType.Add;
		tokens["-="] = TokenType.Minus;
		tokens["<="] = TokenType.LessThanOrEqualTo;
		tokens["lte"] = TokenType.LessThanOrEqualTo;
		tokens["<"] = TokenType.LessThan;
		tokens["lt"] = TokenType.LessThan;
		tokens[">="] = TokenType.GreaterThanOrEqualTo;
		tokens["gte"] = TokenType.GreaterThanOrEqualTo;
		tokens[">"] = TokenType.GreaterThan;
		tokens["gt"] = TokenType.GreaterThan;
	}

	public function resolve(exprs:Array<Expr>, ?compiler:Compiler = null) {
		if (compiler != null) {
			this.compiler = compiler;
		}

		if (this.compiler == null)
			throw "Must have a valid compiler to resolve expressions";

		for (expr in exprs) {
			expr.accept(this);
		}
	}

	public function visitExprParens(expr:Expr.ExprParens):Dynamic {
		return expr.expression.accept(this);
	}

	public function visitExprAssign(expr:Expr.ExprAssign):Dynamic {
		expr.value.accept(this);

		compiler.emit(OpCode.STORE_VARIABLE, [Operand.fromString(expr.name.lexeme)]);
		compiler.emit(OpCode.POP, []);

		return 0;
	};

	public function visitExprNegative(expr:Expr.ExprNegative):Dynamic {
		expr.expression.accept(this);

		compiler.emit(OpCode.PUSH_FLOAT, [Operand.fromFloat(1)]);
		compiler.emit(OpCode.CALL_FUNC, [Operand.fromString(TokenType.UnaryMinus.getName())]);

		return 0;
	}

	public function visitExprNot(expr:Expr.ExprNot):Dynamic {
		expr.expression.accept(this);

		compiler.emit(OpCode.PUSH_FLOAT, [Operand.fromFloat(1)]);
		compiler.emit(OpCode.CALL_FUNC, [Operand.fromString(TokenType.Not.getName())]);

		return 0;
	}

	public function visitExprMultDivMod(expr:Expr.ExprMultDivMod):Dynamic {
		genericExpVisitor(expr.left, expr.right, expr.op);

		return 0;
	}

	public function visitExprAddSub(expr:Expr.ExprAddSub):Dynamic {
		genericExpVisitor(expr.left, expr.right, expr.op);

		return 0;
	}

	public function visitExprComparison(expr:Expr.ExprComparision):Dynamic {
		genericExpVisitor(expr.left, expr.right, expr.op);

		return 0;
	}

	public function visitExprEquality(expr:Expr.ExprEquality):Dynamic {
		genericExpVisitor(expr.left, expr.right, expr.op);

		return 0;
	}

	public function visitExprMultDivModEquals(expr:Expr.ExprMultDivModEquals):Dynamic {
		opEquals(expr.variableName.lexeme, expr.left, expr.op);

		return 0;
	}

	public function visitExprPlusMinusEquals(expr:Expr.ExprPlusMinusEquals):Dynamic {
		opEquals(expr.variableName.lexeme, expr.left, expr.op);

		return 0;
	}

	public function visitExprAndOrXor(expr:Expr.ExprAndOrXor):Dynamic {
		genericExpVisitor(expr.left, expr.right, expr.op);

		return 0;
	}

	public function visitExprValue(expr:Expr.ExprValue):Dynamic {
		switch (expr.value.type) {
			case src.hxyarn.compiler.Token.TokenType.VAR_ID:
				compiler.emit(OpCode.PUSH_VARIABLE, [Operand.fromString(expr.value.lexeme)]);
			case src.hxyarn.compiler.Token.TokenType.NUMBER:
				var number = expr.value.literal;
				compiler.emit(OpCode.PUSH_FLOAT, [Operand.fromFloat(number)]);
			case src.hxyarn.compiler.Token.TokenType.KEYWORD_TRUE:
				compiler.emit(OpCode.PUSH_BOOL, [Operand.fromBool(true)]);
			case src.hxyarn.compiler.Token.TokenType.KEYWORD_FALSE:
				compiler.emit(OpCode.PUSH_BOOL, [Operand.fromBool(false)]);
			case src.hxyarn.compiler.Token.TokenType.STRING:
				compiler.emit(OpCode.PUSH_STRING, [Operand.fromString(expr.value.literal)]);
			case src.hxyarn.compiler.Token.TokenType.KEYWORD_NULL:
				compiler.emit(OpCode.PUSH_NULL, []);
			case _:
				throw 'Expresion value not implemented: ${expr.value.toString()}';
		}

		return 0;
	}

	public function visitExprFunc(expr:Expr.ExprFunc):Dynamic {
		for (arg in expr.arguments) {
			arg.accept(this);
		}

		compiler.emit(OpCode.PUSH_FLOAT, [Operand.fromFloat(expr.arguments.length)]);
		compiler.emit(OpCode.CALL_FUNC, [Operand.fromString(expr.callee)]);

		return 0;
	};

	function opEquals(varName:String, expr:Expr, op:Token) {
		compiler.emit(OpCode.PUSH_VARIABLE, [Operand.fromString(varName)]);

		expr.accept(this);

		compiler.emit(OpCode.PUSH_FLOAT, [Operand.fromFloat(2)]);
		compiler.emit(OpCode.CALL_FUNC, [Operand.fromString(tokens[op.lexeme].getName())]);

		compiler.emit(OpCode.STORE_VARIABLE, [Operand.fromString(varName)]);
		compiler.emit(OpCode.POP, []);
	}

	function genericExpVisitor(left:Expr, right:Expr, op:src.hxyarn.compiler.Token) {
		left.accept(this);
		right.accept(this);

		compiler.emit(OpCode.PUSH_FLOAT, [Operand.fromFloat(2)]);
		compiler.emit(OpCode.CALL_FUNC, [Operand.fromString(tokens[op.lexeme].getName())]);
	}
}
