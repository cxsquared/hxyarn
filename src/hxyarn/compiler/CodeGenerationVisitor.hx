package src.hxyarn.compiler;

import src.hxyarn.compiler.Value.ValueString;
import src.hxyarn.compiler.Value.ValueFalse;
import src.hxyarn.compiler.Value.ValueTrue;
import src.hxyarn.compiler.Value.ValueNumber;
import src.hxyarn.compiler.Value.ValueNull;
import src.hxyarn.compiler.Value.ValueFunctionCall;
import src.hxyarn.program.types.TypeUtils;
import src.hxyarn.program.types.IType;
import src.hxyarn.program.Operator;
import src.hxyarn.compiler.Value.ValueVariable;
import src.hxyarn.compiler.BaseVisitor;
import src.hxyarn.program.Operand;
import src.hxyarn.compiler.Stmt;
import src.hxyarn.program.Instruction.OpCode;
import src.hxyarn.compiler.Expr;
import src.hxyarn.compiler.Compiler;
import src.hxyarn.compiler.Stmt.StmtLine;
import src.hxyarn.compiler.Stmt.StmtSet;

class CodeGenerationVisitor extends BaseVisitor {
	var compiler:Compiler;
	var labelCount:Int = 0;
	var ifStatementEndLabels = new List<String>();
	var generateClauseLabels = new List<String>();

	public function new(compiler:Compiler) {
		this.compiler = compiler;
	}

	function generateCodeForExpressionsInFormattedText(nodes:Array<Dynamic>):Int {
		var expressionCount = 0;

		for (node in nodes) {
			if (Std.isOfType(node, Token))
				continue; // handled in StringTableGeneartorVistior

			if (Std.isOfType(node, Expr)) {
				var expression = cast(node, Expr);
				expression.accept(this);
				expressionCount++;
			}
		}

		return expressionCount;
	}

	public override function visitLine(stmt:StmtLine):Dynamic {
		var expressionCount = generateCodeForExpressionsInFormattedText(stmt.formattedText.children);

		var hashtags = stmt.hashtags != null ? stmt.hashtags.map(function(h:StmtHashtag) {
			return h.text.lexeme;
		}) : null;
		var lineId = compiler.getLineIdTag(hashtags);
		if (lineId == null)
			throw "line needs an id";

		compiler.emit(OpCode.RUN_LINE, [Operand.fromString(lineId), Operand.fromFloat(expressionCount)]);

		return 0;
	}

	public override function visitSet(stmt:StmtSet):Dynamic {
		switch (stmt.op.type) {
			case OPERATOR_ASSIGNMENT:
				stmt.expression.accept(this);
			case OPERATOR_MATHS_ADDITION_EQUALS:
				generateCodeForOperations(Operator.ADD, stmt.expression.type, [stmt.variable, stmt.expression]);
			case OPERATOR_MATHS_SUBTRACTION_EQUALS:
				generateCodeForOperations(Operator.MINUS, stmt.expression.type, [stmt.variable, stmt.expression]);
			case OPERATOR_MATHS_MULTIPLICATION_EQUALS:
				generateCodeForOperations(Operator.MULTIPLY, stmt.expression.type, [stmt.variable, stmt.expression]);
			case OPERATOR_MATHS_DIVISION_EQUALS:
				generateCodeForOperations(Operator.DIVIDE, stmt.expression.type, [stmt.variable, stmt.expression]);
			case OPERATOR_MATHS_MODULUS_EQUALS:
				generateCodeForOperations(Operator.MODULO, stmt.expression.type, [stmt.variable, stmt.expression]);
			case _:
		}

		var variableName = stmt.variable.varId.lexeme;
		compiler.emit(OpCode.STORE_VARIABLE, [Operand.fromString(variableName)]);
		compiler.emit(OpCode.POP, []);

		return 0;
	}

	public override function visitCall(stmt:StmtCall):Dynamic {
		stmt.functionCall.accept(this);

		return 0;
	}

	public override function visitCommand(stmt:StmtCommand):Dynamic {
		var expressionCount = 0;
		var sb = new StringBuf();

		for (node in stmt.formattedText.children) {
			if (Std.isOfType(node, Token)) {
				sb.add(cast(node, Token).lexeme);
			} else if (Std.isOfType(node, Expr)) {
				var expression = cast(node, Expr);
				expression.accept(this);
				sb.add('{$expressionCount}');
				expressionCount++;
			}
		}

		var composedString = sb.toString();

		switch (composedString) {
			case "stop":
				compiler.emit(OpCode.STOP, []);
			case _:
				compiler.emit(OpCode.RUN_COMMAND, [Operand.fromString(composedString), Operand.fromFloat(expressionCount)]);
		}

		return 0;
	}

	public override function visitFunctionCall(stmt:ValueFunctionCall):Dynamic {
		var name = stmt.functionId.lexeme;
		handleFunction(name, stmt.expressions);

		return 0;
	}

	public override function visitIf(stmt:StmtIf):Dynamic {
		// TODO: AddErrorNode?
		var endOfIfStatementLabel = compiler.registerLabel("endif");

		var ifClause = stmt.ifClause;
		generateClause(endOfIfStatementLabel, ifClause.statements, ifClause.expression);

		for (elseIfClause in stmt.elseIfClauses) {
			generateClause(endOfIfStatementLabel, elseIfClause.statements, elseIfClause.expression);
		}

		if (stmt.elseClause != null) {
			generateClause(endOfIfStatementLabel, stmt.elseClause.statements, null);
		}

		compiler.currentNode.labels.set(endOfIfStatementLabel, compiler.currentNode.instructions.length);

		return 0;
	}

	public override function visitShortcutOptionStatement(stmt:StmtShortcutOptionStatement):Dynamic {
		var endOfGroupLabel = compiler.registerLabel("group_end");

		var labels = new Array<String>();

		var optionCount = 0;

		for (shortcut in stmt.options) {
			var nodeName = "node";
			if (compiler.currentNode != null && compiler.currentNode.name != null && compiler.currentNode.name != "")
				nodeName = compiler.currentNode.name;

			var optionDestinationLabel = compiler.registerLabel('shortcutoption_${nodeName}_${optionCount + 1}');
			labels.push(optionDestinationLabel);

			var hasLineCondition = false;
			if (shortcut.lineStatement.condition != null) {
				shortcut.lineStatement.condition.accept(this);

				hasLineCondition = true;
			}

			var expressionCount = generateCodeForExpressionsInFormattedText(shortcut.lineStatement.formattedText.children);

			var lineIdTag = compiler.getLineIdTag(shortcut.lineStatement.hashtags.map(function(h:StmtHashtag) {
				return h.text.lexeme;
			}));

			if (lineIdTag == null)
				throw "Internal error: no line id provided";

			compiler.emit(OpCode.ADD_OPTIONS, [
				Operand.fromString(lineIdTag),
				Operand.fromString(optionDestinationLabel),
				Operand.fromFloat(expressionCount),
				Operand.fromBool(hasLineCondition)
			]);

			optionCount++;
		}

		compiler.emit(OpCode.SHOW_OPTIONS, []);
		compiler.emit(OpCode.JUMP, []);

		optionCount = 0;
		for (shortcut in stmt.options) {
			compiler.currentNode.labels.set(labels[optionCount], compiler.currentNode.instructions.length);

			for (child in shortcut.statements) {
				child.accept(this);
			}

			compiler.emit(OpCode.JUMP_TO, [Operand.fromString(endOfGroupLabel)]);

			optionCount++;
		}

		compiler.currentNode.labels.set(endOfGroupLabel, compiler.currentNode.instructions.length);
		compiler.emit(OpCode.POP, []);

		return 0;
	}

	public override function visitExprParens(expr:ExprParens):Dynamic {
		return expr.expression.accept(this);
	}

	public override function visitExprNegative(expr:ExprNegative):Dynamic {
		generateCodeForOperations(Operator.UNARY_MINUS, expr.type, [expr.expression]);

		return 0;
	}

	public override function visitExprValue(expr:ExprValue):Dynamic {
		return expr.value.accept(this);
	}

	public override function visitExprMultDivMod(expr:ExprMultDivMod):Dynamic {
		generateCodeForOperations(OperatorUtils.tokensToOperators[expr.op.type], expr.type, [expr.left, expr.right]);

		return 0;
	}

	public override function visitExprAddSub(expr:ExprAddSub):Dynamic {
		generateCodeForOperations(OperatorUtils.tokensToOperators[expr.op.type], expr.type, [expr.left, expr.right]);

		return 0;
	}

	public override function visitExprComparison(expr:ExprComparision):Dynamic {
		generateCodeForOperations(OperatorUtils.tokensToOperators[expr.op.type], expr.type, [expr.left, expr.right]);

		return 0;
	}

	public override function visitExprEquality(expr:ExprEquality):Dynamic {
		generateCodeForOperations(OperatorUtils.tokensToOperators[expr.op.type], expr.type, [expr.left, expr.right]);

		return 0;
	}

	public override function visitExprAndOrXor(expr:ExprAndOrXor):Dynamic {
		generateCodeForOperations(OperatorUtils.tokensToOperators[expr.op.type], expr.type, [expr.left, expr.right]);

		return 0;
	}

	public override function visitValueNumber(value:ValueNumber):Dynamic {
		var number = Std.parseFloat(value.literal);
		compiler.emit(OpCode.PUSH_FLOAT, [Operand.fromFloat(number)]);

		return 0;
	}

	public override function visitValueTrue(value:ValueTrue):Dynamic {
		compiler.emit(OpCode.PUSH_BOOL, [Operand.fromBool(true)]);

		return 0;
	}

	public override function visitValueFalse(value:ValueFalse):Dynamic {
		compiler.emit(OpCode.PUSH_BOOL, [Operand.fromBool(false)]);

		return 0;
	}

	public override function visitValueVariable(value:ValueVariable):Dynamic {
		var name = value.varId.lexeme;
		compiler.emit(OpCode.PUSH_VARIABLE, [Operand.fromString(name)]);

		return 0;
	}

	public override function visitValueString(value:ValueString):Dynamic {
		var stringVal = StringTools.trim(value.literal);

		compiler.emit(OpCode.PUSH_STRING, [Operand.fromString(stringVal)]);

		return 0;
	}

	public override function visitValueNull(value:ValueNull):Dynamic {
		compiler.emit(OpCode.PUSH_NULL, []);

		return 0;
	}

	public override function visitJumpToNodeName(stmt:StmtJumpToNodeName):Dynamic {
		// TODO figure out why I need to trim here
		compiler.emit(OpCode.PUSH_STRING, [Operand.fromString(StringTools.trim(stmt.destination.lexeme))]);
		compiler.emit(OpCode.RUN_NODE, []);

		return 0;
	}

	public override function visitJumpToExpression(stmt:StmtJumpToExpression):Dynamic {
		stmt.expr.accept(this);
		compiler.emit(OpCode.RUN_NODE, []);

		return 0;
	}

	function generateCodeForOperations(op:Operator, type:IType, operands:Array<Dynamic>):Dynamic {
		for (operand in operands) {
			if (Std.isOfType(operand, Expr)) {
				var expression = cast(operand, Expr);
				expression.accept(this);
				continue;
			}

			if (Std.isOfType(operand, ValueVariable)) {
				var variable = cast(operand, ValueVariable);
				variable.accept(this);
				continue;
			}
		}

		compiler.emit(OpCode.PUSH_FLOAT, [Operand.fromFloat(operands.length)]);

		var implementingType = TypeUtils.findImplementingTypeForMethod(type, op.getName());

		if (implementingType == null)
			throw "No implementation found for operator " + op.getName();

		var functionName = TypeUtils.getCanonicalNameforMethod(implementingType, op.getName());

		this.compiler.emit(OpCode.CALL_FUNC, [Operand.fromString(functionName)]);

		return 0;
	}

	function generateClause(jumpLabel:String, children:Array<Stmt>, condition:Expr) {
		var endOfCluase = compiler.registerLabel("skipclause");

		if (condition != null) {
			condition.accept(this);
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

	public override function visitVariable(stmt:ValueVariable):Dynamic {
		var variableName = stmt.varId.lexeme;
		compiler.emit(OpCode.STORE_VARIABLE, [Operand.fromString(variableName)]);
		compiler.emit(OpCode.POP, []);

		return 0;
	}

	function handleFunction(funcName:String, parameters:Array<Expr>) {
		for (parameter in parameters) {
			parameter.accept(this);
		}

		compiler.emit(OpCode.PUSH_FLOAT, [Operand.fromFloat(parameters.length)]);
		compiler.emit(OpCode.CALL_FUNC, [Operand.fromString(funcName)]);
	}
}
