package src.hxyarn.compiler;

import haxe.macro.Expr.TypeDefKind;
import haxe.ds.GenericStack;
import haxe.Exception;
import src.hxyarn.compiler.Token.TokenType;

class Scanner {
	var source:String;
	var tokens:Array<Token> = new Array<Token>();

	var start:Int = 0;
	var current:Int = 0;
	var line:Int = 1;

	var keywords = new Map<String, TokenType>();

	var mode = new GenericStack<ScannerMode>();

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
		if (!mode.isEmpty()) {
			switch (mode.first()) {
				case BodyMode:
					bodyMode(c);
				case HeaderMode:
					headerMode(c);
				case _:
					rootMode(c);
			}
		}
	}

	function rootMode(c:String) {
		switch (c) {
			// one char
			case '(':
				addToken(LPAREN);
			case ')':
				addToken(RPAREN);
			case '{':
				addToken(FORMAT_FUNCTION_START);
			case '}':
				addToken(FORMAT_FUNCTION_END);
			case ',':
				addToken(COMMA);
			case '^':
				addToken(OPERATOR_LOGICAL_XOR);
			case ':':
				addToken(HEADER_DELIMITER);
				consumeWhitespace();
				mode.add(HeaderMode);
			// two char
			case '%':
				addToken(match("=") ? OPERATOR_MATHS_MODULUS_EQUALS : OPERATOR_MATHS_MODULUS);
			case '-':
				addToken(match("=") ? OPERATOR_MATHS_SUBTRACTION_EQUALS : OPERATOR_MATHS_SUBTRACTION);
			case '*':
				addToken(match("=") ? OPERATOR_MATHS_MULTIPLICATION_EQUALS : OPERATOR_MATHS_MULTIPLICATION);
			case '/':
				addToken(match("=") ? OPERATOR_MATHS_DIVISION_EQUALS : OPERATOR_MATHS_DIVISION);
			case '+':
				addToken(match("=") ? OPERATOR_MATHS_ADDITION_EQUALS : OPERATOR_MATHS_ADDITION);
			case '!':
				addToken(match("=") ? OPERATOR_LOGICAL_NOT_EQUALS : OPERATOR_LOGICAL_NOT);
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
			case '\\':
				match("\\") ? restOfTheLine() : throw new Exception('Unexpected single forward slash (\\) at line $line');
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

	function headerMode(c:String) {
		switch (c) {
			// whitespace
			// one char
			// two char
			// three char
			case _:
				throw new Exception('Unexpected char at line $line: $c');
		}
	}

	function bodyMode(c:String) {
		switch (c) {
			// whitespace
			case ' ':
			case '\r':
			case '\t':
			case '\n':
				line++;
			// one char
			case '{':
				addToken(TEXT_EXPRESSION_START);
				mode.add(TextMode);
				mode.add(ExpressionMode);
			// two char
			case '-':
				match(">") ? addToken(SHORTCUT_ARROW) : mode.add(TextMode);
			case '<':
				match("<") ? {
					mode.add(CommandMode);
					addToken(COMMAND_START);
				} : mode.add(TextMode);
			case '[':
				match("[") ? {mode.add(OptionMode); addToken(OPTION_START);} : {addToken(FORMAT_FUNCTION_START); mode.add(TextMode); mode.add(FormatFunctionMode);};
			case '#':
				addToken(BODY_HASHTAG);
				mode.add(TextCommandOrHashtagMode);
				mode.add(HashtagMode);
			// three char
			case '=': match('=') && match('=') ? {
					addToken(BODY_END);
					mode.pop();
				} : mode.add(TextMode);
			case _:
				mode.add(TextMode);
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
		var value = source.substr(start + 1, current - 2 - start);
		addToken(STRING, value);
	}

	function restOfTheLine() {
		while (peek() != '\n' && !isAtEnd()) {
			advance();
		}

		line++;
		advance();
	}

	function consumeWhitespace() {
		while (!isAtEnd() && match(' ')) {
			advance();
		}
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

enum ScannerMode {
	BodyMode;
	HeaderMode;
	HashtagMode;
	TextMode;
	TextCommandOrHashtagMode;
	FormatFunctionMode;
	ExpressionMode;
	CommandMode;
	CommandTextMode;
	OptionMode;
	OptionIDMode;
}
