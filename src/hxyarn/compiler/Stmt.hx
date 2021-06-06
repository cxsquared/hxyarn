package src.hxyarn.compiler;

import haxe.Exception;

interface StmtVisitor {
	function visitDialogue(stmt:StmtDialogue):Dynamic;
	function visitFileHashtag(stmt:StmtFileHashtag):Dynamic;
	function visitNode(stmt:StmtNode):Dynamic;
	function visitHeader(stmt:StmtHeader):Dynamic;
	function visitBody(stmt:StmtBody):Dynamic;
	function visitLine(stmt:StmtLine):Dynamic;
	function visitIf(stmt:StmtIf):Dynamic;
	function visitSetExpression(stmt:StmtSetExpression):Dynamic;
	function visitSetVariable(stmt:StmtSetVariable):Dynamic;
	function visitOption(stmt:StmtOption):Dynamic;
	function visitShortcut(stmt:StmtShortcut):Dynamic;
	function visitCall(stmt:StmtCall):Dynamic;
	function visitCommand(stmt:StmtCommand):Dynamic;
	function visitIndent(stmt:StmtIndent):Dynamic;
	function visitExpression(stmt:StmtExpression):Dynamic;
}

class Stmt {
	public function accept(visitor:StmtVisitor):Dynamic {
		throw new Exception("This should be overriden");
	};
}

class StmtDialogue extends Stmt {
	public function new(hashtag:Array<StmtFileHashtag>, nodes:Array<StmtNode>) {
		this.hashtag = hashtag;
		this.nodes = nodes;
	}

	override public function accept(visitor:StmtVisitor) {
		return visitor.visitDialogue(this);
	}

	public var hashtag:Array<StmtFileHashtag>;
	public var nodes:Array<StmtNode>;
}

class StmtFileHashtag extends Stmt {
	public function new(text:Token) {
		this.text = text;
	}

	override public function accept(visitor:StmtVisitor) {
		return visitor.visitFileHashtag(this);
	}

	public var text:Token;
}

class StmtNode extends Stmt {
	public function new(headers:Array<StmtHeader>, body:StmtBody) {
		this.headers = headers;
		this.body = body;
	}

	override public function accept(visitor:StmtVisitor) {
		return visitor.visitNode(this);
	}

	public var headers:Array<StmtHeader>;
	public var body:StmtBody;
}

class StmtHeader extends Stmt {
	public function new(id:Token, value:Token) {
		this.id = id;
		this.value = value;
	}

	override public function accept(visitor:StmtVisitor) {
		return visitor.visitHeader(this);
	}

	public var id:Token;
	public var value:Token;
}

class StmtBody extends Stmt {
	public function new(statements:Array<Stmt>) {
		this.statements = statements;
	}

	override public function accept(visitor:StmtVisitor) {
		return visitor.visitBody(this);
	}

	public var statements:Array<Stmt>;
}

class StmtLine extends Stmt {
	public function new(text:Token) {
		this.text = text;
	}

	override public function accept(visitor:StmtVisitor) {
		return visitor.visitLine(this);
	}

	public var text:Token;
}

class StmtIf extends Stmt {
	public function new(condition:Expr, thenStmt:Stmt, elseStmt:Stmt) {
		this.condition = condition;
		this.thenStmt = thenStmt;
		this.elseStmt = elseStmt;
	}

	override public function accept(visitor:StmtVisitor) {
		return visitor.visitIf(this);
	}

	public var condition:Expr;
	public var thenStmt:Stmt;
	public var elseStmt:Stmt;
}

class StmtSetExpression extends Stmt {
	public function new() {}

	override public function accept(visitor:StmtVisitor) {
		return visitor.visitSetExpression(this);
	}
}

class StmtSetVariable extends Stmt {
	public function new(varId:Token) {}

	override public function accept(visitor:StmtVisitor) {
		return visitor.visitSetVariable(this);
	}

	public var var_id:Token;
	public var expression:Expr;
}

class StmtOption extends Stmt {
	public function new() {}

	override public function accept(visitor:StmtVisitor) {
		return visitor.visitOption(this);
	}
}

class StmtShortcut extends Stmt {
	public function new() {}

	override public function accept(visitor:StmtVisitor) {
		return visitor.visitShortcut(this);
	}
}

class StmtCall extends Stmt {
	public function new() {}

	override public function accept(visitor:StmtVisitor) {
		return visitor.visitCall(this);
	}
}

class StmtCommand extends Stmt {
	public function new() {}

	override public function accept(visitor:StmtVisitor) {
		return visitor.visitCommand(this);
	}
}

class StmtIndent extends Stmt {
	public function new() {}

	override public function accept(visitor:StmtVisitor) {
		return visitor.visitIndent(this);
	}
}

class StmtExpression extends Stmt {
	public function new(expression:Expr) {
		this.expression = expression;
	}

	override public function accept(visitor:StmtVisitor) {
		return visitor.visitExpression(this);
	}

	public var expression:Expr;
}
