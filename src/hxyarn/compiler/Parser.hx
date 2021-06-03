package src.hxyarn.compiler;

package src.hxyarn.compiler;

import src.hxyarn.compiler.Expr.ExpValue;
import src.hxyarn.compiler.Expr.ExpFunc;
import haxe.Exception;
import src.hxyarn.compiler.Token.TokenType;

class ExpressionParser {
	var tokens = new Array<Token>();
	var current = 0;

	public function new(tokens:Array<Token>) {
		this.tokens = tokens;
	}

	public function parse():Array<Expr> {
		var expressions = new Array<Expr>();

		while (!isAtEnd()) {
			expressions.push(expression());
		}

		return expressions;
	}

	function expression():Expr {
		return assignment();
	}

	function assignment() {
		var expr = or();

		if (match([
			OPERATOR_ASSIGNMENT,
			OPERATOR_ASSIGNMENT_MINUS,
			OPERATOR_ASSIGNMENT_MOD,
			OPERATOR_ASSIGNMENT_PLUS,
			OPERATOR_ASSIGNMENT_SLASH,
			OPERATOR_ASSIGNMENT_STAR
		])) {
			var op = previous();
			var value = assignment();

			if (Std.isOfType(expr, Expr.ExpValue)) {
				if (op.type == OPERATOR_ASSIGNMENT_MINUS || op.type == OPERATOR_ASSIGNMENT_PLUS) {
					return new Expr.ExpPlusMinusEquals(cast(expr, Expr.ExpValue).value, op, value);
				} else if (op.type != OPERATOR_ASSIGNMENT) {
					return new Expr.ExpMultDivModEquals(cast(expr, Expr.ExpValue).value, op, value);
				}

				return new Expr.ExpAssign(cast(expr, Expr.ExpValue).value, value);
			}

			throw new Exception("Invalid assignment target.");
		}

		return expr;
	}

	function or():Expr {
		var expr = and();

		while (match([TokenType.OPERATOR_LOGICAL_OR])) {
			var op = previous();
			var right = and();
			expr = new Expr.ExpAndOrXor(expr, op, right);
		}
		return expr;
	}

	function and():Expr {
		var expr = xor();

		while (match([TokenType.OPERATOR_LOGICAL_AND])) {
			var op = previous();
			var right = xor();
			expr = new Expr.ExpAndOrXor(expr, op, right);
		}

		return expr;
	}

	function xor():Expr {
		var expr = equality();

		while (match([TokenType.OPERATOR_LOGICAL_XOR])) {
			var op = previous();
			var right = equality();
			expr = new Expr.ExpAndOrXor(expr, op, right);
		}

		return expr;
	}

	function equality():Expr {
		var expr = comparision();

		while (match([TokenType.OPERATOR_LOGICAL_NOT_EQUALS, TokenType.OPERATOR_LOGICAL_EQUALS])) {
			var op = previous();
			var right = comparision();
			expr = new Expr.ExpEquality(expr, op, right);
		}

		return expr;
	}

	function comparision():Expr {
		var expr = term();

		while (match([
			TokenType.OPERATOR_LOGICAL_LESS_THAN_EQUALS,
			TokenType.OPERATOR_LOGICAL_GREATER_THAN_EQUALS,
			TokenType.OPERATOR_LOGICAL_LESS,
			TokenType.OPERATOR_LOGICAL_GREATER
		])) {
			var op = previous();
			var right = term();
			expr = new Expr.ExpComparision(expr, op, right);
		}

		return expr;
	}

	function term():Expr {
		var expr = factor();

		while (match([TokenType.PLUS, TokenType.MINUS])) {
			var op = previous();
			var right = factor();
			expr = new Expr.ExpAddSub(expr, op, right);
		}

		return expr;
	}

	function factor():Expr {
		var expr = unary();

		while (match([TokenType.SLASH, TokenType.STAR, TokenType.MOD])) {
			var op = previous();
			var right = unary();
			expr = new Expr.ExpMultDivMod(expr, op, right);
		}

		return expr;
	}

	function unary():Expr {
		if (match([TokenType.OPERATOR_LOGICAL_NOT])) {
			var right = unary();
			return new Expr.ExpNot(right);
		}

		if (match([TokenType.MINUS])) {
			var right = unary();
			return new Expr.ExpNegative(right);
		}

		return call();
	}

	function call() {
		var expr = primary();

		while (true) {
			if (match([TokenType.LPAREN])) {
				expr = finishCall(expr);
			} else {
				break;
			}
		}

		return expr;
	}

	function finishCall(callee:Expr) {
		var arguments = new Array<Expr>();
		if (!check(TokenType.RPAREN)) {
			do {
				if (arguments.length >= 255)
					throw new Exception("Can't have more than 255 arguments");

				arguments.push(expression());
			} while (match([TokenType.COMMA]));
		}

		var paren = consume(RPAREN, "Expected ')' after the argumetns.");

		return new ExpFunc(cast(callee, ExpValue).literal, paren, arguments);
	}

	function primary():Expr {
		if (match([TokenType.KEYWORD_FALSE]))
			return new Expr.ExpValue(previous(), false);

		if (match([TokenType.KEYWORD_TRUE]))
			return new Expr.ExpValue(previous(), true);
		if (match([TokenType.KEYWORD_NULL]))
			return new Expr.ExpValue(previous(), null);

		if (match([TokenType.NUMBER, TokenType.STRING, TokenType.VAR_ID]))
			return new Expr.ExpValue(previous(), previous().lexeme);

		if (match([LPAREN])) {
			var expr = expression();
			consume(TokenType.RPAREN, "Expected ')' after expression");
			return new Expr.ExpParens(expr);
		}

		throw new Exception("Expect epxression");
	}

	function match(types:Array<TokenType>):Bool {
		for (type in types) {
			if (check(type)) {
				advance();
				return true;
			}
		}

		return false;
	}

	function consume(type:TokenType, message:String):Token {
		if (check(type))
			return advance();

		throw new Exception('Error at $type: $message');
	}

	function check(type:TokenType):Bool {
		if (isAtEnd())
			return false;
		return peek().type == type;
	}

	function advance():Token {
		if (!isAtEnd())
			current++;
		return previous();
	}

	function isAtEnd()
		return peek().type == TokenType.EOF;

	function peek():Token {
		return tokens[current];
	}

	function previous():Token {
		return tokens[current - 1];
	}
}
