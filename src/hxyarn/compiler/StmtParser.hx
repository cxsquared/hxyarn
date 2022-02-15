package src.hxyarn.compiler;

import src.hxyarn.compiler.Value.ValueFunctionCall;
import src.hxyarn.compiler.Value.ValueVariable;
import src.hxyarn.compiler.Value.ValueNumber;
import src.hxyarn.compiler.Value.ValueString;
import src.hxyarn.compiler.Value.ValueNull;
import src.hxyarn.compiler.Value.ValueTrue;
import src.hxyarn.compiler.Value.ValueFalse;
import src.hxyarn.compiler.Stmt.StmtSet;
import src.hxyarn.compiler.Stmt.StmtCommandFormattedText;
import src.hxyarn.compiler.Stmt.StmtHashtag;
import src.hxyarn.compiler.Stmt.StmtLineCondition;
import src.hxyarn.compiler.Stmt.StmtElseClause;
import src.hxyarn.compiler.Stmt.StmtElseIfClause;
import src.hxyarn.compiler.Stmt.StmtIfClause;
import src.hxyarn.compiler.Stmt.StmtDeclare;
import src.hxyarn.compiler.Stmt.StmtJump;
import src.hxyarn.compiler.Stmt.StmtShortcutOption;
import src.hxyarn.compiler.Stmt.StmtShortcutOptionStatement;
import src.hxyarn.compiler.Stmt.StmtLineFormattedText;
import src.hxyarn.compiler.Stmt.StmtCall;
import src.hxyarn.compiler.Stmt.StmtIf;
import src.hxyarn.compiler.Stmt.StmtLine;
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
		consume(NEWLINE, "Expected newline");
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
		if (match([NEWLINE]))
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
		// shortcut
		if (match([SHORTCUT_ARROW]))
			return shortcutOptionStatement();

		// command
		if (match([COMMAND_START])) {
			// if
			if (match([COMMAND_IF]))
				return ifStatement();

			// set
			if (match([COMMAND_SET]))
				return setStatement();

			// call
			if (match([COMMAND_CALL]))
				return callStatement();

			// declare
			if (match([COMMAND_DECLARE]))
				return declareStatement();

			// jump
			if (match([COMMAND_JUMP]))
				return jumpStatement();

			if (match([COMMAND_TEXT, COMMAND_EXPRESSION_START]))
				return commandFormattedText();
		}

		// TODO indent/dedent
		// line
		return lineStatement();
	}

	function shortcutOptionStatement():StmtShortcutOptionStatement {
		var options = [shortcutOption()];
		while (match([SHORTCUT_ARROW])) {
			options.push(shortcutOption());
		}

		return new StmtShortcutOptionStatement(options);
	}

	function shortcutOption():StmtShortcutOption {
		var line = lineStatement();
		// TODO indent/dedent
		return new StmtShortcutOption(line);
	}

	function ifStatement():StmtIf {
		var ifClause = ifClauseStatement();
		var elseIfClauses = new Array<StmtElseIfClause>();
		var elseClause:StmtElseClause = null;
		while (match([COMMAND_START])) {
			if (match([COMMAND_ELSEIF]))
				elseIfClauses.push(elseIfClauseStatement());

			if (match([COMMAND_ELSE]))
				elseClause = elseClauseStatement();
		}
		consume(COMMAND_ENDIF, "expected end of if statement");
		consume(COMMAND_END, "expected end of if statement");

		return new StmtIf(ifClause, elseIfClauses, elseClause);
	}

	function ifClauseStatement():StmtIfClause {
		var expression = expression();
		consume(COMMAND_END, "expected end of if clause");

		var statements = new Array<Stmt>();
		while (peekForward(1).type != COMMAND_ELSEIF && peekForward(1).type != COMMAND_ELSE && peekForward(1).type != COMMAND_ENDIF) {
			statements.push(statement());
		}

		return new StmtIfClause(expression, statements);
	}

	function elseIfClauseStatement():StmtElseIfClause {
		var expression = expression();
		consume(COMMAND_END, "Expected >>");
		var statements = new Array<Stmt>();
		while (peekForward(1).type != COMMAND_ELSEIF && peekForward(1).type != COMMAND_ELSE && peekForward(1).type != COMMAND_ENDIF) {
			statements.push(statement());
		}

		return new StmtElseIfClause(expression, statements);
	}

	function elseClauseStatement():StmtElseClause {
		consume(COMMAND_END, "Expected >>");
		var statements = new Array<Stmt>();
		while (peekForward(1).type != COMMAND_ENDIF) {
			statements.push(statement());
		}

		return new StmtElseClause(statements);
	}

	function variable():ValueVariable {
		var id = consume(VAR_ID, "expected variable");
		return new ValueVariable(id, id.lexeme);
	}

	function setStatement():Stmt {
		var variable = variable();
		var op:Token;
		if (match([
			OPERATOR_ASSIGNMENT,
			OPERATOR_MATHS_MULTIPLICATION_EQUALS,
			OPERATOR_MATHS_DIVISION_EQUALS,
			OPERATOR_MATHS_MODULUS_EQUALS,
			OPERATOR_MATHS_ADDITION_EQUALS,
			OPERATOR_MATHS_SUBTRACTION_EQUALS
		])) {
			op = previous();
		} else {
			throw "Expected operator";
		}
		var expr = expression();
		consume(COMMAND_END, "expected >>");
		return new StmtSet(variable, op, expr);
	}

	function callStatement():StmtCall {
		return new StmtCall(functionCall());
	}

	function functionCall():ValueFunctionCall {
		var id = consume(FUNC_ID, "Expected Id");
		consume(LPAREN, "expected (");
		if (match([LPAREN])) {
			return new ValueFunctionCall(id, new Array<Expr>());
		}

		var exprs = new Array<Expr>();
		exprs.push(expression());
		while (match([COMMA])) {
			exprs.push(expression());
		}
		consume(RPAREN, "expected )");
		consume(COMMAND_END, "expected >>");

		return new ValueFunctionCall(id, exprs);
	}

	function jumpStatement():StmtJump {
		if (match([EXPRESSION_START])) {
			var expression = expression();
			consume(EXPRESSION_END, "expected }");
			consume(COMMAND_END, "expected >>");
			return new StmtJump(null, expression);
		}

		var destination = consume(ID, "Expected Id");
		consume(COMMAND_END, "expected >>");
		return new StmtJump(destination);
	}

	function declareStatement():StmtDeclare {
		var variable = variable();
		consume(OPERATOR_ASSIGNMENT, "expected =");
		var value = value();
		var as:Token = null;
		if (match([EXPRESSION_AS])) {
			as = consume(EXPRESSION_AS, "Expected as");
		}

		return new StmtDeclare(variable, value, as);
	}

	function commandFormattedText():Stmt {
		// TODO handle expressions
		var texts = new Array<Dynamic>();
		texts.push(previous());
		while (!match([COMMAND_TEXT_END])) {
			texts.push(consume(COMMAND_TEXT, "Expected Text"));
		}
		return new StmtCommandFormattedText(texts);
	}

	function lineStatement():StmtLine {
		var lineFormattedText = lineFormatedText();
		var condition:StmtLineCondition = null;
		if (match([COMMAND_START]))
			condition = lineCondition();

		var hashTags = new Array<StmtHashtag>();
		while (match([HASHTAG])) {
			hashTags.push(hashtag());
		}

		consume(NEWLINE, "Expected newline");

		return new StmtLine(lineFormattedText, condition, hashTags);
	}

	function lineFormatedText():StmtLineFormattedText {
		var text = new Array<Dynamic>();
		while (peek().type == TEXT || peek().type == EXPRESSION_START) {
			if (peek().type == TEXT) {
				text.push(consume(TEXT, "Expected Text"));
			} else {
				consume(EXPRESSION_START, "Expected Expression Start");
				text.push(expression());
				consume(EXPRESSION_END, "Expected Expression End");
			}
		}

		return new StmtLineFormattedText(text);
	}

	function lineCondition():StmtLineCondition {
		consume(COMMAND_IF, "Expected if");
		var expression = expression();
		consume(COMMAND_END, "Expected >>");

		return new StmtLineCondition(expression);
	}

	function hashtag():StmtHashtag {
		return new StmtHashtag(consume(HASHTAG_TEXT, "Expected Hashtag"));
	}

	function expression():Expr {
		return assignment();
	}

	function assignment():Expr {
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
				var variableToken = cast(expr, Expr.ExprValue).value;
				var variable = new ValueVariable(variableToken.value, variableToken.literal);
				if (op.type == OPERATOR_MATHS_SUBTRACTION_EQUALS || op.type == OPERATOR_MATHS_ADDITION_EQUALS) {
					return new Expr.ExprPlusMinusEquals(variable, op, value);
				} else if (op.type != OPERATOR_ASSIGNMENT) {
					return new Expr.ExprMultDivModEquals(variable, op, value);
				}

				return new Expr.ExprAssign(variable, value);
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

		return value();
	}

	function value():Expr {
		if (match([TokenType.KEYWORD_FALSE]))
			return new Expr.ExprValue(new ValueFalse(previous()));

		if (match([TokenType.KEYWORD_TRUE]))
			return new Expr.ExprValue(new ValueTrue(previous()));

		if (match([TokenType.KEYWORD_NULL]))
			return new Expr.ExprValue(new ValueNull(previous()));

		if (match([TokenType.NUMBER]))
			return new Expr.ExprValue(new ValueNumber(previous(), previous().lexeme));

		if (match([TokenType.STRING]))
			return new Expr.ExprValue(new ValueString(previous(), previous().lexeme));

		if (peek().type == TokenType.VAR_ID)
			return new Expr.ExprValue(variable());

		if (peek().type == TokenType.FUNC_ID)
			return new Expr.ExprValue(functionCall());

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
