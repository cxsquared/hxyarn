package hxyarn.compiler;

import hxyarn.compiler.Stmt.StmtJumpOption;
import hxyarn.compiler.Stmt.StmtJumpToExpression;
import hxyarn.compiler.Stmt.StmtJumpToNodeName;
import hxyarn.compiler.Stmt.StmtCommand;
import hxyarn.compiler.Value.ValueFunctionCall;
import hxyarn.compiler.Value.ValueVariable;
import hxyarn.compiler.Value.ValueNumber;
import hxyarn.compiler.Value.ValueString;
import hxyarn.compiler.Value.ValueNull;
import hxyarn.compiler.Value.ValueTrue;
import hxyarn.compiler.Value.ValueFalse;
import hxyarn.compiler.Stmt.StmtSet;
import hxyarn.compiler.Stmt.StmtCommandFormattedText;
import hxyarn.compiler.Stmt.StmtHashtag;
import hxyarn.compiler.Stmt.StmtLineCondition;
import hxyarn.compiler.Stmt.StmtElseClause;
import hxyarn.compiler.Stmt.StmtElseIfClause;
import hxyarn.compiler.Stmt.StmtIfClause;
import hxyarn.compiler.Stmt.StmtDeclare;
import hxyarn.compiler.Stmt.StmtJump;
import hxyarn.compiler.Stmt.StmtShortcutOption;
import hxyarn.compiler.Stmt.StmtShortcutOptionStatement;
import hxyarn.compiler.Stmt.StmtJumpOption;
import hxyarn.compiler.Stmt.StmtJumpOptionStatement;
import hxyarn.compiler.Stmt.StmtLineFormattedText;
import hxyarn.compiler.Stmt.StmtCall;
import hxyarn.compiler.Stmt.StmtIf;
import hxyarn.compiler.Stmt.StmtLine;
import hxyarn.compiler.Stmt.StmtBody;
import hxyarn.compiler.Stmt.StmtHeader;
import hxyarn.compiler.Stmt.StmtNode;
import hxyarn.compiler.Stmt.StmtDialogue;
import hxyarn.compiler.Stmt.StmtFileHashtag;
import haxe.Exception;
import hxyarn.compiler.Token.TokenType;

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

		var value:Token = null;
		if (peek().type == REST_OF_LINE)
			value = consume(REST_OF_LINE, "");

		return new StmtHeader(id, value);
	}

	function body():StmtBody {
		var stmts = new Array<Stmt>();
		while (!match([BODY_END])) {
			stmts = stmts.concat(statement());
		}

		return new StmtBody(stmts);
	}

	function statement():Array<Stmt> {
		// shortcut
		if (match([SHORTCUT_ARROW]))
			return [shortcutOptionStatement()];

		// command
		if (match([COMMAND_START])) {
			// if
			if (match([COMMAND_IF]))
				return [ifStatement()];

			// set
			if (match([COMMAND_SET]))
				return [setStatement()];

			// call
			if (match([COMMAND_CALL]))
				return [callStatement()];

			// declare
			if (match([COMMAND_DECLARE]))
				return [declareStatement()];

			// jump
			if (match([COMMAND_JUMP]))
				return [jumpStatement()];

			if (match([COMMAND_TEXT, COMMAND_EXPRESSION_START])) {
				var text = commandFormattedText();
				var hashtags:Array<StmtHashtag> = [];
				while (match([HASHTAG])) {
					hashtags.push(hashtag());
				}

				return [new StmtCommand(text, hashtags)];
			}
		}

		if (match([JUMP_OPTION_START])) {
			return [jumpOptionStatement()];
		}

		if (match([INDENT])) {
			var statements = new Array<Stmt>();
			while (!match([DEDENT])) {
				statements = statements.concat(statement());
			}

			return statements;
		}

		// TODO indent/dedent
		// line
		return [lineStatement()];
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
		var statements = new Array<Stmt>();
		if (match([INDENT])) {
			while (!match([DEDENT])) {
				statements = statements.concat(statement());
			}
		}
		return new StmtShortcutOption(line, statements);
	}

	function jumpOptionStatement():StmtJumpOptionStatement {
		var options = [jumpOption()];
		while (match([JUMP_OPTION_START])) {
			options.push(jumpOption());
		}

		return new StmtJumpOptionStatement(options);
	}

	function jumpOption():StmtJumpOption {
		var lineFormattedText = jumpOptionFormattedText();
		var hashTags = new Array<StmtHashtag>();
		var statementLine = new StmtLine(lineFormattedText, null, hashTags);
		var destination = consume(JUMP_OPTION_LINK, "Expected Jump Option Link");
		var jumpLinkStmt = new StmtJumpToNodeName(destination);
		consume(JUMP_OPTION_END, "expected ]]");

		return new StmtJumpOption(statementLine, [jumpLinkStmt]);
	}

	function jumpOptionFormattedText():StmtLineFormattedText {
		var texts = new Array<Dynamic>();
		while (!match([JUMP_OPTION_LINK])) {
			if (match([COMMAND_EXPRESSION_START])) {
				texts.push(expression());
				consume(EXPRESSION_END, "expected }");
			} else {
				texts.push(consume(TEXT, "expected text"));
			}
		}
		return new StmtLineFormattedText(texts);
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
			statements = statements.concat(statement());
		}

		return new StmtIfClause(expression, statements);
	}

	function elseIfClauseStatement():StmtElseIfClause {
		var expression = expression();
		consume(COMMAND_END, "Expected >>");
		var statements = new Array<Stmt>();
		while (peekForward(1).type != COMMAND_ELSEIF && peekForward(1).type != COMMAND_ELSE && peekForward(1).type != COMMAND_ENDIF) {
			statements = statements.concat(statement());
		}

		return new StmtElseIfClause(expression, statements);
	}

	function elseClauseStatement():StmtElseClause {
		consume(COMMAND_END, "Expected >>");
		var statements = new Array<Stmt>();
		while (peekForward(1).type != COMMAND_ENDIF) {
			statements = statements.concat(statement());
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
		var func = functionCall();

		consume(COMMAND_END, "expected >>");
		return new StmtCall(func);
	}

	function functionCall():ValueFunctionCall {
		var id = consume(FUNC_ID, "Expected Id");
		consume(LPAREN, "expected (");
		if (match([LPAREN])) {
			return new ValueFunctionCall(id, new Array<Expr>());
		}

		var exprs = new Array<Expr>();
		if (peek().type != RPAREN) {
			exprs.push(expression());
			while (match([COMMA])) {
				exprs.push(expression());
			}
		}
		consume(RPAREN, "expected )");

		return new ValueFunctionCall(id, exprs);
	}

	function jumpStatement():StmtJump {
		if (match([EXPRESSION_START])) {
			return new StmtJump(jumpToExpression());
		}

		return new StmtJump(jumpToNodeName());
	}

	function jumpToExpression():StmtJumpToExpression {
		var expression = expression();
		consume(EXPRESSION_END, "expected }");
		consume(COMMAND_END, "expected >>");
		return new StmtJumpToExpression(expression);
	}

	function jumpToNodeName():StmtJumpToNodeName {
		var destination = consume(ID, "Expected Id");
		consume(COMMAND_END, "expected >>");
		return new StmtJumpToNodeName(destination);
	}

	function declareStatement():StmtDeclare {
		var variable = variable();
		consume(OPERATOR_ASSIGNMENT, "expected =");
		var value = value();
		var as:Token = null;
		if (match([EXPRESSION_AS])) {
			as = consume(FUNC_ID, "Expected Id");
		}
		consume(COMMAND_END, "expected >>");

		return new StmtDeclare(variable, value, as);
	}

	function commandStatement():StmtCommand {
		var formattedText = commandFormattedText();
		var hashtags = new Array<StmtHashtag>();
		while (match([HASHTAG])) {
			hashtags.push(hashtag());
		}
		return new StmtCommand(formattedText, hashtags);
	}

	function commandFormattedText():StmtCommandFormattedText {
		var texts = new Array<Dynamic>();
		texts.push(previous());
		while (!match([COMMAND_TEXT_END])) {
			if (match([COMMAND_EXPRESSION_START])) {
				texts.push(expression());
				consume(EXPRESSION_END, "expected }");
			} else {
				texts.push(consume(COMMAND_TEXT, "expected text"));
			}
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
			return new Expr.ExprValue(new ValueString(previous()));

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
