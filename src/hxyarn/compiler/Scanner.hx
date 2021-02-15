package src.hxyarn.compiler;

import src.hxyarn.compiler.Token.TokenType;

class Scanner {
    var source:String;
    var tokens:Array<Token> = new Array<Token>();

    var start:Int = 0;
    var current:Int = 0;
    var line:Int = 1;

    public function Scanner(source:String) {
        this.source = source;
    }

    function scanTokens():Array<Token> {
        while(!isAtEnd()) {
            start = current;
            scanToken();
        }

        tokens.push(new Token(EOF, "", null, line, ""));
        return tokens;
    }

    function scanToken() {
        var c = advance();
        switch(c) {
            case '(': addToken(LPAREN);
            case ')': addToken(RPAREN);
            case '{': addToken(LBRACE);
            case '}': addToken(RBRACE);
            case ',': addToken(COMMA);
            case '.': addToken(DOT);
            case '-': addToken(MINUS);
            case '+': addToken(PLUS);
            case '*': addToken(STAR);
            case '!': addToken(match("=") ? OPERATOR_LOGICAL_NOT_EQUALS : BANG);
            case '=': addToken(match("=") ? OPERATOR_LOGICAL_EQUALS : OPERATOR_ASSIGNMENT);
            case '<': addToken(match("=") ? OPERATOR_LOGICAL_LESS_THAN_EQUALS : OPERATOR_LOGICAL_LESS);
            case '>': addToken(match("=") ? OPERATOR_LOGICAL_GREATER_THAN_EQUALS : OPERATOR_LOGICAL_EQUALS);
            case '\n': line++;
            case '"': string(); 
            case _: Compiler.error(line, "Unexpected character.");
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
        if (isAtEnd()) return false;
        if (source.charAt(current) != expected) return false;

        current++;
        return true;
    }

    function peek():String {
        if(isAtEnd()) return "\\0";
        return source.charAt(current);
    }

    function string() {
        while(peek() != '"' && !isAtEnd()) {
            if (peek() == '\n') line++;
            advance();
        }

        if (isAtEnd()) {
            Compiler.error(line, "Unterminated string.");
            return;
        }

        advance();
        var value = source.substr(start + 1, current - 1);
        addTokenWithLiteral(STRING, value);
    }

    function addToken(type:TokenType) {
        addTokenWithLiteral(type, null);
    }

    function addTokenWithLiteral(type:TokenType, literal:Dynamic) {
        var text = source.substr(start, current);
        tokens.push(new Token(type, text, literal, line, ""));
    }
}