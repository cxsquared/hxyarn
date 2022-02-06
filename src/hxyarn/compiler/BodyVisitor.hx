package src.hxyarn.compiler;

import src.hxyarn.compiler.ExpressionVisitor.ExpresionVisitor;
import src.hxyarn.program.Instruction;
import src.hxyarn.program.Operand;
import src.hxyarn.program.Node;
import src.hxyarn.compiler.Stmt;
import src.hxyarn.program.Instruction.OpCode;
import src.hxyarn.compiler.Expr;
import src.hxyarn.program.VirtualMachine.TokenType;
import src.hxyarn.compiler.Compiler;
import src.hxyarn.compiler.Stmt.StmtDialogue;
import src.hxyarn.compiler.Stmt.StmtFileHashtag;
import src.hxyarn.compiler.Stmt.StmtNode;
import src.hxyarn.compiler.Stmt.StmtHeader;
import src.hxyarn.compiler.Stmt.StmtBody;
import src.hxyarn.compiler.Stmt.StmtLine;
import src.hxyarn.compiler.Stmt.StmtIf;
import src.hxyarn.compiler.Stmt.StmtSetExpression;
import src.hxyarn.compiler.Stmt.StmtSetVariable;
import src.hxyarn.compiler.Stmt.StmtOption;
import src.hxyarn.compiler.Stmt.StmtShortcut;
import src.hxyarn.compiler.Stmt.StmtCall;
import src.hxyarn.compiler.Stmt.StmtCommand;
import src.hxyarn.compiler.Stmt.StmtIndent;
import src.hxyarn.compiler.Stmt.StmtExpression;
import src.hxyarn.compiler.Stmt.StmtVisitor;

class BodyVisitor implements StmtVisitor {
	var compiler:Compiler;
	var labelCount:Int = 0;
	var ifStatementEndLabels = new List<String>();
	var generateClauseLabels = new List<String>();
	var expressionVisitor:ExpresionVisitor;

	public function new(compiler:Compiler) {
		this.compiler = compiler;
		expressionVisitor = new ExpresionVisitor(compiler);
	}

	public function resolve(body:StmtBody) {
		for (stmt in body.statements) {
			stmt.accept(this);
		}
	}

	public function visitDialogue(stmt:StmtDialogue):Dynamic {
		for (hashtag in stmt.hashtags) {
			hashtag.accept(this);
		}
		for (node in stmt.nodes) {
			compiler.currentNode = new Node();
			node.accept(this);
		}

		return 0;
	}

	public function visitFileHashtag(stmt:StmtFileHashtag):Dynamic {
		compiler.currentNode.labels.set(stmt.text.lexeme, compiler.currentNode.instructions.length);
		return 0;
	}

	public function visitNode(stmt:StmtNode):Dynamic {
		throw new haxe.exceptions.NotImplementedException();
	}

	public function visitHeader(stmt:StmtHeader):Dynamic {
		throw new haxe.exceptions.NotImplementedException();
	}

	public function visitBody(stmt:StmtBody):Dynamic {
		for (stmt in stmt.statements) {
			stmt.accept(this);
		}

		return 0;
	}

	public function visitLine(stmt:StmtLine):Dynamic {
		// TODO: Resolving inline expression
		// TODO: Add hashtag to StmtLine
		var hashtagText = "";
		var formattedText = {
			composedString: StringTools.trim(stmt.text.lexeme),
			expressionCount: 0
		};

		var lineId = compiler.getLineId(hashtagText);
		var stringId = compiler.registerString(StringTools.trim(formattedText.composedString), lineId, stmt.text.line, [hashtagText]);

		compiler.emit(OpCode.RUN_LINE, [Operand.fromString(stringId), Operand.fromFloat(formattedText.expressionCount)]);

		return 0;
	}

	public function visitIf(stmt:StmtIf):Dynamic {
		var endOfIfStatmentLabel = compiler.registerLabel("endif");
		ifStatementEndLabels.push(endOfIfStatmentLabel);

		var ifClause = stmt.thenBranch;
		generateClause(endOfIfStatmentLabel, ifClause, stmt.condition);

		// TODO: Implement else if

		if (stmt.elseBranch.length > 0) {
			generateClause(endOfIfStatmentLabel, stmt.elseBranch, null);
		}

		compiler.currentNode.labels.set(endOfIfStatmentLabel, compiler.currentNode.instructions.length);

		return 0;
	}

	function generateClause(jumpLabel:String, children:Array<Stmt>, condition:Expr) {
		var endOfCluase = compiler.registerLabel("skipclause");

		if (condition != null) {
			expressionVisitor.resolve([condition]);
			compiler.emit(OpCode.JUMP_IF_FALSE, [Operand.fromString(jumpLabel)]);
		}

		for (stmt in children) {
			stmt.accept(this);
		}

		compiler.emit(OpCode.JUMP_TO, [Operand.fromString(jumpLabel)]);

		if (condition != null) {
			compiler.currentNode.labels.set(endOfCluase, compiler.currentNode.instructions.length);
			compiler.emit(OpCode.POP, []);
		}
	}

	public function visitSetExpression(stmt:StmtSetExpression):Dynamic {
		var expression = stmt.expression;
		if (Std.isOfType(expression, ExprMultDivModEquals) || Std.isOfType(expression, ExprPlusMinusEquals)) {
			expressionVisitor.resolve([expression]);
		} else {
			throw "Invalid expression inside assignment statement";
		}

		return 0;
	}

	public function visitSetVariable(stmt:StmtSetVariable):Dynamic {
		expressionVisitor.resolve([stmt.expression]);

		var variableName = stmt.var_id.lexeme;
		compiler.emit(OpCode.STORE_VARIABLE, [Operand.fromString(variableName)]);
		compiler.emit(OpCode.POP, []);

		return 0;
	}

	public function visitOption(stmt:StmtOption):Dynamic {
		// TODO support hashtag
		// TODO support formating
		var formatedText = {
			composedString: StringTools.trim(stmt.text.lexeme),
			expressionCount: 0
		};
		var desitnation = StringTools.trim(stmt.node_id.lexeme);
		var label = formatedText.composedString;

		var lineId = compiler.getLineId("");
		var stringId = compiler.registerString(label, lineId, stmt.text.line, []);

		compiler.emit(OpCode.ADD_OPTIONS, [
			Operand.fromString(stringId),
			Operand.fromString(desitnation),
			Operand.fromFloat(0)
		]);

		return 0;
	}

	public function visitOptionJump(stmt:StmtOptionJump):Dynamic {
		var destination = StringTools.trim(stmt.node_id.lexeme);
		compiler.emit(OpCode.RUN_NODE, [Operand.fromString(destination)]);

		return 0;
	}

	public function visitShortcut(stmt:StmtShortcut):Dynamic {
		// TODO
		throw new haxe.exceptions.NotImplementedException();
	}

	public function visitCall(stmt:StmtCall):Dynamic {
		var funcName = stmt.id.lexeme;

		handleFunction(funcName, stmt.epxressions);

		return 0;
	}

	function handleFunction(funcName:String, parameters:Array<Expr>) {
		for (parmeter in parameters) {
			expressionVisitor.resolve([parmeter]);
		}

		compiler.emit(OpCode.PUSH_FLOAT, [Operand.fromFloat(parameters.length)]);
		compiler.emit(OpCode.CALL_FUNC, [Operand.fromString(funcName)]);
	}

	public function visitCommand(stmt:StmtCommand):Dynamic {
		var composedString = "";

		for (token in stmt.texts) {
			composedString += token.lexeme;
		}

		switch (composedString) {
			case "stop":
				compiler.emit(OpCode.STOP, []);
			case _:
				compiler.emit(OpCode.RUN_COMMAND, [Operand.fromString(composedString), Operand.fromFloat(0)]);
		}

		return 0;
	}

	public function visitIndent(stmt:StmtIndent):Dynamic {
		// TODO
		throw new haxe.exceptions.NotImplementedException();
	}

	public function visitExpression(stmt:StmtExpression):Dynamic {
		var visitor = new ExpresionVisitor(compiler);
		visitor.resolve([stmt.expression]);

		return 0;
	}
}
