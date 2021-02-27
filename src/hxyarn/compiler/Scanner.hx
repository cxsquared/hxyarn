package src.hxyarn.compiler;

import haxe.display.Display.Keyword;
import haxe.Exception;
import src.hxyarn.compiler.Token.TokenType;

class Scanner {
	var source:String;
	var tokens:Array<Token> = new Array<Token>();

	var start:Int = 0;
	var current:Int = 0;
	var line:Int = 1;

	var keywords = new Map<String, TokenType>();

	public function new(source:String) {
		this.source = source;

		keywords.set("or", OPERATOR_LOGICAL_OR);
		keywords.set("and", OPERATOR_LOGICAL_AND);
		keywords.set("is", OPERATOR_LOGICAL_EQUALS);
		keywords.set("lt", OPERATOR_LOGICAL_LESS);
		keywords.set("lte", OPERATOR_LOGICAL_LESS_THAN_EQUALS);
		keywords.set("gt", OPERATOR_LOGICAL_GREATER);
		keywords.set("gte", OPERATOR_LOGICAL_GREATER_THAN_EQUALS);
		keywords.set("not", OPERATOR_LOGICAL_NOT);
		keywords.set("neq", OPERATOR_LOGICAL_NOT_EQUALS);
		keywords.set("xor", OPERATOR_LOGICAL_XOR);
		keywords.set("false", KEYWORD_FALSE);
		keywords.set("true", KEYWORD_TRUE);
		keywords.set("null", KEYWORD_NULL);
		keywords.set("to", OPERATOR_ASSIGNMENT);
	}

	public static function scan(source:String) {
		return new Scanner(source).scanTokens();
	}

	function scanTokens():Array<Token> {
		while (!isAtEnd()) {
			start = current;
			scanToken();
		}

		tokens.push(new Token(EOF, "", null, line, ""));
		return tokens;
	}

	function scanToken() {
		var c = advance();
		switch (c) {
			// one char
			case '(':
				addToken(LPAREN);
			case ')':
				addToken(RPAREN);
			case '{':
				addToken(LBRACE);
			case '}':
				addToken(RBRACE);
			case ',':
				addToken(COMMA);
			case '.':
				addToken(DOT);
			case '^':
				addToken(OPERATOR_LOGICAL_XOR);
			// two char
			case '-':
				addToken(match("=") ? OPERATOR_ASSIGNMENT_MINUS : MINUS);
			case '*':
				addToken(match("=") ? OPERATOR_ASSIGNMENT_STAR : STAR);
			case '/':
				addToken(match("=") ? OPERATOR_ASSIGNMENT_SLASH : SLASH);
			case '+':
				addToken(match("=") ? OPERATOR_ASSIGNMENT_PLUS : PLUS);
			case '!':
				addToken(match("=") ? OPERATOR_LOGICAL_NOT_EQUALS : BANG);
			case '=':
				addToken(match("=") ? OPERATOR_LOGICAL_EQUALS : OPERATOR_ASSIGNMENT);
			case '<':
				addToken(match("=") ? OPERATOR_LOGICAL_LESS_THAN_EQUALS : OPERATOR_LOGICAL_LESS);
			case '>':
				addToken(match("=") ? OPERATOR_LOGICAL_GREATER_THAN_EQUALS : OPERATOR_LOGICAL_EQUALS);
			case '|':
				match("|") ? addToken(OPERATOR_LOGICAL_OR) : throw new Exception('Unexpected single pipe (|) at line $line');
			case '&':
				match("&") ? addToken(OPERATOR_LOGICAL_AND) : throw new Exception('Unexpected single ampersand (&) at line $line');
			// white spaces
			case ' ':
			case '\r':
			case '\t':
			case '\n':
				line++;
			case '"':
				string();
			case _:
				if (isDigit(c)) {
					number();
					return;
				}
				if (isAlpha(c)) {
					identifier();
					return;
				}
				throw new Exception('Unexpected char at line $line: $c');
		}
	}

	function isAtEnd():Bool {
		return current >= source.length;
	}

	function advance():String {
		current++;
		return source.charAt(current - 1);
	}

	function match(expected:String):Bool {
		if (isAtEnd())
			return false;
		if (source.charAt(current) != expected)
			return false;

		current++;
		return true;
	}

	function peek():String {
		if (isAtEnd())
			return "\\0";
		return source.charAt(current);
	}

	function peekNext() {
		if (current + 1 >= source.length)
			return '\\0';
		return source.charAt(current + 1);
	}

	function string() {
		while (peek() != '"' && !isAtEnd()) {
			if (peek() == '\n')
				line++;
			advance();
		}

		if (isAtEnd()) {
			throw new Exception('Unterminated string at line $line');
		}

		advance();
		var value = source.substr(start + 1, current - 1 - start);
		addToken(STRING, value);
	}

	function number() {
		while (isDigit(peek()))
			advance();

		if (peek() == '.' && isDigit(peekNext())) {
			advance();

			while (isDigit(peek()))
				advance();
		}

		addToken(TokenType.NUMBER, Std.parseFloat(source.substr(start, current - start)));
	}

	function identifier() {
		while (isAlphaNumeric(peek()))
			advance();

		var text = source.substr(start, current - start);

		var type = keywords.get(text);
		if (type == null)
			type = VAR_ID;

		addToken(type);
	}

	function addToken(type:TokenType, ?literal:Dynamic = null) {
		var text = source.substr(start, current - start);
		tokens.push(new Token(type, text, literal, line, ""));
	}

	function isDigit(c:String):Bool {
		return c >= '0' && c <= '9';
	}

	var alpha = ~/^[a-zA-Z_$]+$/;

	function isAlpha(c:String):Bool {
		return alpha.match(c);
		// return  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_';
	}

	function isAlphaNumeric(c:String):Bool {
		return isAlpha(c) || isDigit(c);
	}
}
