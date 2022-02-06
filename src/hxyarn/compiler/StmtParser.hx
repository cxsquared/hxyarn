package src.hxyarn.compiler;

import src.hxyarn.compiler.Stmt.StmtOptionJump;
import src.hxyarn.compiler.Stmt.StmtOption;
import src.hxyarn.compiler.Stmt.StmtCall;
import src.hxyarn.compiler.Stmt.StmtSetVariable;
import src.hxyarn.compiler.Stmt.StmtSetExpression;
import src.hxyarn.compiler.Stmt.StmtIf;
import src.hxyarn.compiler.Stmt.StmtLine;
import src.hxyarn.compiler.Stmt.StmtCommand;
import src.hxyarn.compiler.Stmt.StmtBody;
import src.hxyarn.compiler.Stmt.StmtHeader;
import src.hxyarn.compiler.Stmt.StmtNode;
import src.hxyarn.compiler.Stmt.StmtDialogue;
import src.hxyarn.compiler.Stmt.StmtFileHashtag;
import haxe.Exception;
import src.hxyarn.compiler.Token.TokenType;

class StmtParser {
	var tokens = new Array<Token>();
	var current = 0;

	public function new(tokens:Array<Token>) {
		this.tokens = tokens;
	}

	public function parse():StmtDialogue {
		return dialogue();
	}

	function dialogue():StmtDialogue {
		var hashtags = new Array<StmtFileHashtag>();
		while (match([HASHTAG]) && match([HASHTAG_TEXT])) {
			hashtags.push(fileHashtag());
		}

		var nodes = new Array<StmtNode>();
		while (!isAtEnd()) {
			nodes.push(node());
		}

		return new StmtDialogue(hashtags, nodes);
	}

	function fileHashtag():StmtFileHashtag {
		var value = previous();
		consume(TEXT_COMMANDHASHTAG_NEWLINE, "Expected newline");
		return new StmtFileHashtag(value);
	}

	function node():StmtNode {
		var headers = new Array<StmtHeader>();
		while (!match([BODY_START])) {
			headers.push(header());
		}

		var body = body();

		return new StmtNode(headers, body);
	}

	function header():StmtHeader {
		var id = consume(ID, "expected header Id");
		consume(HEADER_DELIMITER, "expected header delimiter");
		if (match([HEADER_NEWLINE]))
			return new StmtHeader(id, previous());

		var value = consume(REST_OF_LINE, "");

		return new StmtHeader(id, value);
	}

	function body():StmtBody {
		var stmts = new Array<Stmt>();
		while (!match([BODY_END])) {
			stmts.push(statement());
		}

		return new StmtBody(stmts);
	}

	function statement():Stmt {
		if (match([TEXT]))
			return lineStatement();

		if (match([COMMAND_START]))
			return commandStart();

		if (match([OPTION_START]))
			return optionStart();

		throw "Unexpected statement";
	}

	function commandStart():Stmt {
		if (match([COMMAND_IF]))
			return commandIf();

		if (match([COMMAND_SET]))
			return commandSet();

		if (match([COMMAND_CALL]))
			return commandCall();

		if (match([COMMAND_TEXT]))
			return commandText();

		return throw "";
	}

	function commandIf():Stmt {
		var condition = expression();

		consume(EXPRESSION_COMMAND_END, "Expected Expression End");

		var thenBranch = new Array<Stmt>();
		while (peekForward(1).type != COMMAND_ELSE && peekForward(1).type != COMMAND_ENDIF) {
			thenBranch.push(statement());
		}

		var elseBranch = new Array<Stmt>();
		if (match([COMMAND_START]) && match([COMMAND_ELSE])) {
			consume(COMMAND_END, "Expected >>");
			while (peek().type != COMMAND_START && peekForward(1).type != COMMAND_ENDIF) {
				elseBranch.push(statement());
			}
			consume(COMMAND_START, "Expected <<");
		}

		consume(COMMAND_ENDIF, "Expected endif");
		consume(COMMAND_END, "Expected >>");

		return new StmtIf(condition, thenBranch, elseBranch);
	}

	function commandSet():Stmt {
		var expr:Expr;
		if (peek().type == VAR_ID) {
			var varId = consume(VAR_ID, "");
			consume(OPERATOR_ASSIGNMENT, "");
			expr = expression();
			consume(EXPRESSION_COMMAND_END, "");

			return new StmtSetVariable(varId, expr);
		}

		expr = expression();
		consume(EXPRESSION_COMMAND_END, "");
		return new StmtSetExpression(expr);
	}

	function commandCall():Stmt {
		var id = consume(VAR_ID, "Expected Id");
		consume(LPAREN, "expected (");
		if (match([LPAREN])) {
			return new StmtCall(id, new Array<Expr>());
		}

		var exprs = new Array<Expr>();
		exprs.push(expression());
		while (match([COMMA])) {
			exprs.push(expression());
		}
		consume(RPAREN, "expected )");
		consume(EXPRESSION_COMMAND_END, "expected >>");

		return new StmtCall(id, exprs);
	}

	function commandText():Stmt {
		// TODO handle expressions
		var texts = [previous()];
		while (!match([COMMAND_TEXT_END])) {
			texts.push(consume(COMMAND_TEXT, "Expected Text"));
		}
		return new StmtCommand(texts);
	}

	function optionStart():Stmt {
		// TODO supporting formating
		// TODO support hashtags
		if (match([OPTION_ID])) {
			var destination = previous();
			consume(OPTION_END, "Expected ]]");

			return new StmtOptionJump(destination);
		}

		var text = consume(OPTION_TEXT, "Expected text");
		consume(OPTION_DELIMIT, "Expected |");
		var id = consume(OPTION_ID, "Expected Id");
		consume(OPTION_END, "Expected ]]");

		return new StmtOption(text, id);
	}

	function lineStatement():Stmt {
		return new StmtLine(previous());
	}

	function expression():Expr {
		return assignment();
	}

	function assignment() {
		var expr = or();

		if (match([
			OPERATOR_ASSIGNMENT,
			OPERATOR_MATHS_ADDITION_EQUALS,
			OPERATOR_MATHS_SUBTRACTION_EQUALS,
			OPERATOR_MATHS_MODULUS_EQUALS,
			OPERATOR_MATHS_DIVISION_EQUALS,
			OPERATOR_MATHS_MULTIPLICATION_EQUALS,
		])) {
			var op = previous();
			var value = assignment();

			if (Std.isOfType(expr, Expr.ExprValue)) {
				if (op.type == OPERATOR_MATHS_SUBTRACTION_EQUALS || op.type == OPERATOR_MATHS_ADDITION_EQUALS) {
					return new Expr.ExprPlusMinusEquals(cast(expr, Expr.ExprValue).value, op, value);
				} else if (op.type != OPERATOR_ASSIGNMENT) {
					return new Expr.ExprMultDivModEquals(cast(expr, Expr.ExprValue).value, op, value);
				}

				return new Expr.ExprAssign(cast(expr, Expr.ExprValue).value, value);
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
			expr = new Expr.ExprAndOrXor(expr, op, right);
		}
		return expr;
	}

	function and():Expr {
		var expr = xor();

		while (match([TokenType.OPERATOR_LOGICAL_AND])) {
			var op = previous();
			var right = xor();
			expr = new Expr.ExprAndOrXor(expr, op, right);
		}

		return expr;
	}

	function xor():Expr {
		var expr = equality();

		while (match([TokenType.OPERATOR_LOGICAL_XOR])) {
			var op = previous();
			var right = equality();
			expr = new Expr.ExprAndOrXor(expr, op, right);
		}

		return expr;
	}

	function equality():Expr {
		var expr = comparision();

		while (match([TokenType.OPERATOR_LOGICAL_NOT_EQUALS, TokenType.OPERATOR_LOGICAL_EQUALS])) {
			var op = previous();
			var right = comparision();
			expr = new Expr.ExprEquality(expr, op, right);
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
			expr = new Expr.ExprComparision(expr, op, right);
		}

		return expr;
	}

	function term():Expr {
		var expr = factor();

		while (match([TokenType.OPERATOR_MATHS_ADDITION, TokenType.OPERATOR_MATHS_SUBTRACTION])) {
			var op = previous();
			var right = factor();
			expr = new Expr.ExprAddSub(expr, op, right);
		}

		return expr;
	}

	function factor():Expr {
		var expr = unary();

		while (match([
			TokenType.OPERATOR_MATHS_DIVISION,
			TokenType.OPERATOR_MATHS_MULTIPLICATION,
			TokenType.OPERATOR_MATHS_MODULUS
		])) {
			var op = previous();
			var right = unary();
			expr = new Expr.ExprMultDivMod(expr, op, right);
		}

		return expr;
	}

	function unary():Expr {
		if (match([TokenType.OPERATOR_LOGICAL_NOT])) {
			var right = unary();
			return new Expr.ExprNot(right);
		}

		if (match([TokenType.OPERATOR_MATHS_SUBTRACTION])) {
			var right = unary();
			return new Expr.ExprNegative(right);
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

		return new Expr.ExprFunc(cast(callee, Expr.ExprValue).literal, paren, arguments);
	}

	function primary():Expr {
		if (match([TokenType.KEYWORD_FALSE]))
			return new Expr.ExprValue(previous(), false);

		if (match([TokenType.KEYWORD_TRUE]))
			return new Expr.ExprValue(previous(), true);
		if (match([TokenType.KEYWORD_NULL]))
			return new Expr.ExprValue(previous(), null);

		if (match([TokenType.NUMBER, TokenType.STRING, TokenType.VAR_ID]))
			return new Expr.ExprValue(previous(), previous().lexeme);

		if (match([LPAREN])) {
			var expr = expression();
			consume(TokenType.RPAREN, "Expected ')' after expression");
			return new Expr.ExprParens(expr);
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

	function peekForward(forward:Int):Token {
		if (current + forward >= tokens.length)
			throw "Can't peek forward $forward steps";

		return tokens[current + forward];
	}

	function previous():Token {
		return tokens[current - 1];
	}
}
