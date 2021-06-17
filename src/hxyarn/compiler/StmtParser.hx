package src.hxyarn.compiler;

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

	public function parse():Array<Stmt> {
		var statments = new Array<Stmt>();

		statments.push(dialogue());

		return statments;
	}

	function dialogue():Stmt {
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
		return lineStatement();
	}

	function lineStatement():Stmt {
		if (peek().type == TEXT) {
			return new StmtLine(advance());
		}

		return ifStatement();
	}

	function ifStatement():Stmt {
		return setStatement();
	}

	function setStatement():Stmt {
		return optionStatement();
	}

	function optionStatement():Stmt {
		return shortcutOptionStatement();
	}

	function shortcutOptionStatement():Stmt {
		return callStatement();
	}

	function callStatement():Stmt {
		return commandStatement();
	}

	function commandStatement():Stmt {
		advance();
		return new StmtCommand();
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
