package src.hxyarn.compiler;

import src.hxyarn.compiler.Value.ValueVariable;
import src.hxyarn.compiler.Value.ValueFunctionCall;
import haxe.Exception;

interface StmtVisitor {
	function visitDialogue(stmt:StmtDialogue):Dynamic;
	function visitFileHashtag(stmt:StmtFileHashtag):Dynamic;
	function visitNode(stmt:StmtNode):Dynamic;
	function visitHeader(stmt:StmtHeader):Dynamic;
	function visitBody(stmt:StmtBody):Dynamic;
	function visitLine(stmt:StmtLine):Dynamic;
	function visitLineFormattedText(stmt:StmtLineFormattedText):Dynamic;
	function visitHashTag(stmt:StmtHashtag):Dynamic;
	function visitLineCondition(stmt:StmtLineCondition):Dynamic;
	function visitExpression(stmt:StmtExpression):Dynamic;
	function visitIf(stmt:StmtIf):Dynamic;
	function visitIfClause(stmt:StmtIfClause):Dynamic;
	function visitElseIfClause(stmt:StmtElseIfClause):Dynamic;
	function visitElseClause(stmt:StmtElseClause):Dynamic;
	function visitSet(stmt:StmtSet):Dynamic;
	function visitCall(stmt:StmtCall):Dynamic;
	function visitCommand(stmt:StmtCommand):Dynamic;
	function visitCommandFormattedText(stmt:StmtCommandFormattedText):Dynamic;
	function visitShortcutOptionStatement(stmt:StmtShortcutOptionStatement):Dynamic;
	function visitShortcutOption(stmt:StmtShortcutOption):Dynamic;
	function visitDeclare(stmt:StmtDeclare):Dynamic;
	function visitJump(stmt:StmtJump):Dynamic;
	function visitJumpToNodeName(stmt:StmtJumpToNodeName):Dynamic;
	function visitJumpToExpression(stmt:StmtJumpToExpression):Dynamic;
}

class Stmt {
	public function accept(visitor:StmtVisitor):Dynamic {
		throw new Exception("This should be overriden");
	};
}

class StmtDialogue extends Stmt {
	public function new(hashtags:Array<StmtFileHashtag>, nodes:Array<StmtNode>) {
		this.hashtags = hashtags;
		this.nodes = nodes;
	}

	override public function accept(visitor:StmtVisitor) {
		return visitor.visitDialogue(this);
	}

	public var hashtags(default, null):Array<StmtFileHashtag>;
	public var nodes(default, null):Array<StmtNode>;
}

class StmtFileHashtag extends Stmt {
	public function new(text:Token) {
		if (text.type != HASHTAG_TEXT)
			throw "Expected hashtag text";

		this.text = text;
	}

	override public function accept(visitor:StmtVisitor) {
		return visitor.visitFileHashtag(this);
	}

	public var text(default, null):Token;
}

class StmtNode extends Stmt {
	public function new(headers:Array<StmtHeader>, body:StmtBody) {
		this.headers = headers;
		this.body = body;
	}

	override public function accept(visitor:StmtVisitor) {
		return visitor.visitNode(this);
	}

	public var headers(default, null):Array<StmtHeader>;
	public var body(default, null):StmtBody;
}

class StmtHeader extends Stmt {
	public function new(id:Token, ?value:Token) {
		if (id.type != ID)
			throw "Expected id";

		this.id = id;

		if (value != null && value.type != REST_OF_LINE)
			throw "Expected REST_OF_LINE";

		this.value = value;
	}

	override public function accept(visitor:StmtVisitor) {
		return visitor.visitHeader(this);
	}

	public var id(default, null):Token;
	public var value(default, null):Token;
}

class StmtBody extends Stmt {
	public function new(statements:Array<Stmt>) {
		this.statements = statements;
	}

	override public function accept(visitor:StmtVisitor) {
		return visitor.visitBody(this);
	}

	public var statements(default, null):Array<Stmt>;
}

class StmtLine extends Stmt {
	public function new(formattedText:StmtLineFormattedText, ?condition:StmtLineCondition, ?hashtags:Array<StmtHashtag>) {
		this.formattedText = formattedText;
		this.condition = condition;
		this.hashtags = hashtags;
	}

	override public function accept(visitor:StmtVisitor) {
		return visitor.visitLine(this);
	}

	public var formattedText(default, null):StmtLineFormattedText;
	public var condition(default, null):StmtLineCondition;
	public var hashtags(default, null):Array<StmtHashtag>;
}

class StmtLineFormattedText extends Stmt {
	public function new(children:Array<Dynamic>) {
		if (children.length < 1)
			throw "Expected at least one text or expression";

		var nonValidChildren = children.filter(function(child:Dynamic):Bool {
			if (Std.isOfType(child, Token)) {
				return cast(child, Token).type != TEXT;
			}
			return Std.isOfType(child, Expr);
		});

		if (nonValidChildren.length > 0)
			throw "Expected only text or expression";

		this.children = children;
	}

	public function expressions():Array<Expr> {
		return this.children.filter(function(child:Dynamic):Bool {
			return Std.isOfType(child, Expr);
		}).map(function(child:Dynamic):Expr {
			return cast(child, Expr);
		});
	}

	override public function accept(visitor:StmtVisitor) {
		return visitor.visitLineFormattedText(this);
	}

	public var children(default, null):Array<Dynamic>;
}

class StmtHashtag extends Stmt {
	public function new(text:Token) {
		if (text.type != HASHTAG_TEXT)
			throw "Expected hashtag text";

		this.text = text;
	}

	override public function accept(visitor:StmtVisitor) {
		return visitor.visitHashTag(this);
	}

	public var text(default, null):Token;
}

class StmtLineCondition extends Stmt {
	public function new(expression:Expr) {
		this.expression = expression;
	}

	override public function accept(visitor:StmtVisitor) {
		return visitor.visitLineCondition(this);
	}

	public var expression(default, null):Expr;
}

class StmtExpression extends Stmt {
	public function new(expression:Expr) {
		this.expression = expression;
	}

	override public function accept(visitor:StmtVisitor) {
		return visitor.visitExpression(this);
	}

	public var expression(default, null):Expr;
}

class StmtIf extends Stmt {
	public function new(ifClause:StmtIfClause, ?elseIfClauses:Array<StmtElseIfClause>, ?elseClause:StmtElseClause) {
		this.ifClause = ifClause;
		this.elseIfClauses = elseIfClauses;
		this.elseClause = elseClause;
	}

	override public function accept(visitor:StmtVisitor) {
		return visitor.visitIf(this);
	}

	public var ifClause(default, null):StmtIfClause;
	public var elseIfClauses(default, null):Array<StmtElseIfClause>;
	public var elseClause(default, null):StmtElseClause;
}

class StmtIfClause extends Stmt {
	public function new(expression:Expr, statements:Array<Stmt>) {
		this.expression = expression;
		this.statements = statements;
	}

	override public function accept(visitor:StmtVisitor) {
		return visitor.visitIfClause(this);
	}

	public var expression(default, null):Expr;
	public var statements(default, null):Array<Stmt>;
}

class StmtElseIfClause extends Stmt {
	public function new(expression:Expr, statements:Array<Stmt>) {
		this.expression = expression;
		this.statements = statements;
	}

	override public function accept(visitor:StmtVisitor) {
		return visitor.visitElseIfClause(this);
	}

	public var expression(default, null):Expr;
	public var statements(default, null):Array<Stmt>;
}

class StmtElseClause extends Stmt {
	public function new(statements:Array<Stmt>) {
		this.statements = statements;
	}

	override public function accept(visitor:StmtVisitor) {
		return visitor.visitElseClause(this);
	}

	public var statements(default, null):Array<Stmt>;
}

class StmtSet extends Stmt {
	public function new(variable:ValueVariable, op:Token, expression:Expr) {
		this.variable = variable;
		this.op = op;
		this.expression = expression;
	}

	override public function accept(visitor:StmtVisitor) {
		return visitor.visitSet(this);
	}

	public var variable(default, null):ValueVariable;
	public var op(default, null):Token;
	public var expression(default, null):Expr;
}

class StmtCall extends Stmt {
	public function new(functionCall:ValueFunctionCall) {
		this.functionCall = functionCall;
	}

	override public function accept(visitor:StmtVisitor) {
		return visitor.visitCall(this);
	}

	public var functionCall(default, null):ValueFunctionCall;
}

class StmtCommand extends Stmt {
	public function new(formattedText:StmtCommandFormattedText, ?hashtags:Array<StmtHashtag>) {
		this.formattedText = formattedText;
		this.hashtags = hashtags;
	}

	override public function accept(visitor:StmtVisitor) {
		return visitor.visitCommand(this);
	}

	public var formattedText(default, null):StmtCommandFormattedText;
	public var hashtags(default, null):Array<StmtHashtag>;
}

class StmtCommandFormattedText extends Stmt {
	public function new(children:Array<Dynamic>) {
		if (children.length < 1)
			throw "Expected at least one text or expression";

		var nonValidChildren = children.filter(function(child:Dynamic):Bool {
			if (Std.isOfType(child, Token)) {
				return cast(child, Token).type != COMMAND_TEXT;
			}
			return Std.isOfType(child, Expr);
		});

		if (nonValidChildren.length > 0)
			throw "Expected only text or expression";

		this.children = children;
	}

	override public function accept(visitor:StmtVisitor) {
		return visitor.visitCommandFormattedText(this);
	}

	public var children(default, null):Array<Dynamic>;
}

class StmtShortcutOptionStatement extends Stmt {
	public function new(options:Array<StmtShortcutOption>) {
		if (options.length < 1)
			throw "Expected at least one option";

		this.options = options;
	}

	override public function accept(visitor:StmtVisitor) {
		return visitor.visitShortcutOptionStatement(this);
	}

	public var options(default, null):Array<StmtShortcutOption>;
}

class StmtShortcutOption extends Stmt {
	public function new(lineStatement:StmtLine, ?statements:Array<Stmt>) {
		this.lineStatement = lineStatement;
		this.statements = statements;
	}

	override public function accept(visitor:StmtVisitor) {
		return visitor.visitShortcutOption(this);
	}

	public var lineStatement(default, null):StmtLine;
	public var statements(default, null):Array<Stmt>;
}

class StmtDeclare extends Stmt {
	public function new(variable:ValueVariable, value:Expr, ?as:Token) {
		this.variable = variable;
		this.value = value;
		this.as = as;
	}

	override public function accept(visitor:StmtVisitor) {
		return visitor.visitDeclare(this);
	}

	public var variable(default, null):ValueVariable;
	public var value(default, null):Expr;
	public var as(default, null):Token;
}

class StmtJump extends Stmt {
	public function new(stmt:Stmt) {
		if (!Std.isOfType(stmt, StmtJumpToNodeName) && !Std.isOfType(stmt, StmtJumpToExpression))
			throw "Jump statement needs to be either jump to node or jump to expression";

		this.stmt = stmt;
	}

	override public function accept(visitor:StmtVisitor) {
		return visitor.visitJump(this);
	}

	public var stmt(default, null):Stmt;
}

class StmtJumpToNodeName extends Stmt {
	public function new(destination:Token) {
		this.destination = destination;
	}

	override public function accept(visitor:StmtVisitor) {
		return visitor.visitJumpToNodeName(this);
	}

	public var destination(default, null):Token;
}

class StmtJumpToExpression extends Stmt {
	public function new(expr:Expr) {
		this.expr = expr;
	}

	override public function accept(visitor:StmtVisitor) {
		return visitor.visitJumpToExpression(this);
	}

	public var expr(default, null):Expr;
}
