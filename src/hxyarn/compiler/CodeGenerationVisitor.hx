package src.hxyarn.compiler;

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
import src.hxyarn.compiler.Stmt.StmtBody;
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
		// stmt.expression.accept(this);

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
