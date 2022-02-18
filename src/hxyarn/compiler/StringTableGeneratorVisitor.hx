package hxyarn.compiler;

import hxyarn.compiler.Stmt.StmtHashtag;
import hxyarn.compiler.Stmt.StmtLine;
import hxyarn.compiler.Stmt.StmtNode;

typedef FormattedTextOuput = {outputString:String, expressionCount:Int};

class StringTableGeneratorVisitor extends BaseVisitor {
	var currentNodeName = "";
	var fileName = "";
	var stringTableManager:StringTableManager;
	var compiler:Compiler;

	public function new(fileName:String, stringTableManagmer:StringTableManager, compiler:Compiler) {
		this.fileName = fileName;
		this.stringTableManager = stringTableManagmer;
		this.compiler = compiler;
	}

	public override function visitNode(stmt:StmtNode):Dynamic {
		var tags = new Array<String>();

		for (header in stmt.headers) {
			var headerKey = header.id.lexeme;
			var value = "";
			if (header.value != null) {
				value = header.value.lexeme;
			}

			if (headerKey == "title") {
				currentNodeName = value;
			}

			if (headerKey == "tags") {
				tags = value.split(" ");
			}
		}

		if (currentNodeName == "" && tags.contains("rawText")) {
			// TODO Raw text mode support
		} else {
			var body = stmt.body;
			if (body != null) {
				body.accept(this);
			}
		}

		return 0;
	}

	override function visitLine(stmt:StmtLine):Dynamic {
		var lineNumber = getLineNumberFromChildren(stmt.formattedText.children);

		var hashtagText = stmt.hashtags.map(function(hashtag:StmtHashtag):String {
			return hashtag.text.lexeme;
		});

		var lineIdTag = compiler.getLineIdTag(hashtagText);

		var formattedTextOutput = generateFormattedText(stmt.formattedText.children);

		var stringId = stringTableManager.registerString(formattedTextOutput.outputString, fileName, currentNodeName, lineIdTag, lineNumber, hashtagText);

		if (lineIdTag == null) {
			var hashTag = new StmtHashtag(new Token(HASHTAG_TEXT, stringId, stringId, lineNumber, currentNodeName));
			stmt.hashtags.push(hashTag);
		}

		return 0;
	}

	function getLineNumberFromChildren(children:Array<Dynamic>):Int {
		// TODO probably store line number in stmt
		for (child in children) {
			if (Std.isOfType(child, Token))
				return cast(child, Token).line;
		}

		throw "Could not find line number";
	}

	function generateFormattedText(children:Array<Dynamic>):FormattedTextOuput {
		var expressionCount = 0;
		var sb = new StringBuf();

		for (child in children) {
			if (Std.isOfType(child, Token)) {
				sb.add(cast(child, Token).lexeme);
			} else if (Std.isOfType(child, Expr)) {
				// This assumes we are still getting
				// {} from the text tokens
				// we might need to add those
				// depending on how I'm scanning stuff
				sb.add('{$expressionCount}');
				expressionCount++;
			}
		}

		return {
			outputString: StringTools.trim(sb.toString()),
			expressionCount: expressionCount
		};
	}
}
