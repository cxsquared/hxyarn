package src.hxyarn.compiler;

import src.hxyarn.compiler.Expr.ExpParens;
import src.hxyarn.compiler.Expr.ExpNot;
import src.hxyarn.compiler.Expr.ExpNegative;
import src.hxyarn.compiler.Expr.ExpMultDivMod;
import src.hxyarn.compiler.Expr.ExpAddSub;
import src.hxyarn.compiler.Expr.ExpComparision;
import src.hxyarn.compiler.Expr.ExpEquality;
import src.hxyarn.compiler.Expr.ExpAndOrXor;
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
		return or();
	}

	function or():Expr {
		var expr = and();

		while (match([TokenType.OPERATOR_LOGICAL_OR])) {
			var op = previous();
			var right = and();
			expr = new ExpAndOrXor(expr, op, right);
		}
		return expr;
	}

	function and():Expr {
		var expr = xor();

		while (match([TokenType.OPERATOR_LOGICAL_AND])) {
			var op = previous();
			var right = xor();
			expr = new ExpAndOrXor(expr, op, right);
		}

		return expr;
	}

	function xor():Expr {
		var expr = equality();

		while (match([TokenType.OPERATOR_LOGICAL_XOR])) {
			var op = previous();
			var right = equality();
			expr = new ExpAndOrXor(expr, op, right);
		}

		return expr;
	}

	function equality():Expr {
		var expr = comparision();

		while (match([TokenType.OPERATOR_LOGICAL_NOT_EQUALS, TokenType.OPERATOR_LOGICAL_EQUALS])) {
			var op = previous();
			var right = comparision();
			expr = new ExpEquality(expr, op, right);
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
			expr = new ExpComparision(expr, op, right);
		}

		return expr;
	}

	function term():Expr {
		var expr = factor();

		while (match([TokenType.PLUS, TokenType.MINUS])) {
			var op = previous();
			var right = factor();
			expr = new ExpAddSub(expr, op, right);
		}

		return expr;
	}

	function factor():Expr {
		var expr = unary();

		while (match([TokenType.SLASH, TokenType.STAR, TokenType.MOD])) {
			var op = previous();
			var right = unary();
			expr = new ExpMultDivMod(expr, op, right);
		}

		return expr;
	}

	function unary():Expr {
		if (match([TokenType.OPERATOR_LOGICAL_NOT])) {
			var right = unary();
			return new ExpNot(right);
		}

		if (match([TokenType.MINUS])) {
			var right = unary();
			return new ExpNegative(right);
		}

		return primary();
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
			return new ExpParens(expr);
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
