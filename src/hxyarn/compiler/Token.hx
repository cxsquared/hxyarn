package src.hxyarn.compiler;



class Token {
    public var type:TokenType;
    public var lexeme:String;
    public var literal:Dynamic;
    public var line:Int;
    public var nodeName:String;

    public function new(type:TokenType, lexeme:String, literal:Dynamic, line:Int, nodeName:String) {
        this.type = type;
        this.lexeme = lexeme;
        this.literal = literal;
        this.line = line;
        this.nodeName = nodeName;
    }

    public function toString():String {
       return '${type.getName()} $lexeme $literal';  
    }
}

enum TokenType {
    LPAREN;
    RPAREN;
    MINUS;
    STAR;
    SLASH;
    MOD;
    PLUS;
    BANG;
    COMMA;
    DOT;
    LBRACE;
    RBRACE;

    OPERATOR_LOGICAL_LESS_THAN_EQUALS;
    OPERATOR_LOGICAL_GREATER_THAN_EQUALS;
    OPERATOR_LOGICAL_LESS;
    OPERATOR_LOGICAL_GREATER;
    OPERATOR_LOGICAL_EQUALS;
    OPERATOR_LOGICAL_NOT_EQUALS;
    OPERATOR_ASSIGNMENT;

    NUMBER;
    KEYWORD_TRUE;
    KEYWORD_FALSE;
    STRING;
    KEYWORD_NULL;

    VAR_ID;
    FUNC_ID;
    OPTION_ID;

    OPTION_SHORTCUT; // ->
    OPTION_DOUBLE_LBRACKET; // [[
    OPTION_DOUBLE_RBRACKET; // ]]
    OPTION_PIPE; // |
    OPTION_TEXT;
    OPTION_EXPRESSION_START;
    OPTION_FORMAT_FUNCTION_START;

    COMMAND_START;
    COMMAND_IF;
    COMMAND_ELSEIF;
    COMMAND_ELSE;
    COMMAND_END;
    COMMAND_ENDIF;
    COMMAND_TEXT_END;
    COMMAND_CALL;

    DEDENT;
    INDENT;

    EXPRESSION_END;
    EXPRESSION_COMMAND_END;

    FORMAT_FUNCTION_START;
    FORMAT_FUNCTION_END;
    FORMAT_FUNCTION_ID;
    FORMAT_FUNCTION_STRING;
    FORMAT_FUNCTION_EQUALS;
    FORMAT_FUNCTION_NUMBER;

    BODY_HASHTAG;
    HASHTAG_TAG;
    HASHTAG;
    HASHTAG_TEXT;

    TEXT;
    TEXT_NEWLINE;
    TEXT_COMMANDHASHTAG_NEWLINE;
    TEXT_COMMANDHASHTAG_COMMAND_START;
    TEXT_COMMAND_START;
    TEXT_EXPRESSION_START;
    TEXT_FORMAT_FUNCTION_START;
    TEXT_HASHTAG;
    TEXT_COMMANDHASHTAG_HASHTAG;

    EOF;
}
