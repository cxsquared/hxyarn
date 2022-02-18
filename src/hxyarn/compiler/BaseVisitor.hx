package hxyarn.compiler;

import hxyarn.compiler.Stmt.StmtJumpToNodeName;
import hxyarn.compiler.Stmt.StmtJumpToExpression;
import hxyarn.compiler.Value.ValueVariable;
import hxyarn.compiler.Value.ValueFunctionCall;
import hxyarn.compiler.Value.ValueNumber;
import hxyarn.compiler.Value.ValueTrue;
import hxyarn.compiler.Value.ValueFalse;
import hxyarn.compiler.Value.ValueString;
import hxyarn.compiler.Value.ValueNull;
import hxyarn.compiler.Value.ValueVisitor;
import hxyarn.compiler.Stmt.StmtDialogue;
import hxyarn.compiler.Stmt.StmtFileHashtag;
import hxyarn.compiler.Stmt.StmtNode;
import hxyarn.compiler.Stmt.StmtHeader;
import hxyarn.compiler.Stmt.StmtBody;
import hxyarn.compiler.Stmt.StmtLine;
import hxyarn.compiler.Stmt.StmtLineFormattedText;
import hxyarn.compiler.Stmt.StmtHashtag;
import hxyarn.compiler.Stmt.StmtLineCondition;
import hxyarn.compiler.Stmt.StmtExpression;
import hxyarn.compiler.Stmt.StmtIf;
import hxyarn.compiler.Stmt.StmtIfClause;
import hxyarn.compiler.Stmt.StmtElseIfClause;
import hxyarn.compiler.Stmt.StmtElseClause;
import hxyarn.compiler.Stmt.StmtSet;
import hxyarn.compiler.Stmt.StmtCall;
import hxyarn.compiler.Stmt.StmtCommand;
import hxyarn.compiler.Stmt.StmtCommandFormattedText;
import hxyarn.compiler.Stmt.StmtShortcutOptionStatement;
import hxyarn.compiler.Stmt.StmtShortcutOption;
import hxyarn.compiler.Stmt.StmtDeclare;
import hxyarn.compiler.Stmt.StmtJump;
import hxyarn.compiler.Expr.ExprParens;
import hxyarn.compiler.Expr.ExprAssign;
import hxyarn.compiler.Expr.ExprNegative;
import hxyarn.compiler.Expr.ExprNot;
import hxyarn.compiler.Expr.ExprMultDivMod;
import hxyarn.compiler.Expr.ExprAddSub;
import hxyarn.compiler.Expr.ExprComparision;
import hxyarn.compiler.Expr.ExprEquality;
import hxyarn.compiler.Expr.ExprMultDivModEquals;
import hxyarn.compiler.Expr.ExprPlusMinusEquals;
import hxyarn.compiler.Expr.ExprAndOrXor;
import hxyarn.compiler.Expr.ExprValue;
import hxyarn.compiler.Expr.ExprVisitor;
import hxyarn.compiler.Stmt.StmtVisitor;

class BaseVisitor implements StmtVisitor implements ExprVisitor implements ValueVisitor {
	public function visitDialogue(stmt:StmtDialogue):Dynamic {
		for (hashtag in stmt.hashtags) {
			hashtag.accept(this);
		}
		for (node in stmt.nodes) {
			node.accept(this);
		}

		return 0;
	}

	public function visitFileHashtag(stmt:StmtFileHashtag):Dynamic {
		return stmt.text;
	}

	public function visitNode(stmt:StmtNode):Dynamic {
		for (header in stmt.headers) {
			header.accept(this);
		}
		return stmt.body.accept(this);
	}

	public function visitHeader(stmt:StmtHeader):Dynamic {
		return 0;
	}

	public function visitBody(stmt:StmtBody):Dynamic {
		for (statement in stmt.statements) {
			statement.accept(this);
		}
		return 0;
	}

	public function visitLine(stmt:StmtLine):Dynamic {
		stmt.formattedText.accept(this);

		if (stmt.condition != null)
			stmt.condition.accept(this);

		for (hashtag in stmt.hashtags) {
			hashtag.accept(this);
		}
		return 0;
	}

	public function visitLineFormattedText(stmt:StmtLineFormattedText):Dynamic {
		for (child in stmt.children) {
			if (Std.isOfType(child, Expr))
				child.accept(this);
		}
		return 0;
	}

	public function visitHashTag(stmt:StmtHashtag):Dynamic {
		return 0;
	}

	public function visitLineCondition(stmt:StmtLineCondition):Dynamic {
		stmt.expression.accept(this);
		return 0;
	}

	public function visitExpression(stmt:StmtExpression):Dynamic {
		stmt.expression.accept(this);
		return 0;
	}

	public function visitVariable(stmt:ValueVariable):Dynamic {
		return 0;
	}

	public function visitFunctionCall(stmt:ValueFunctionCall):Dynamic {
		for (expression in stmt.expressions) {
			expression.accept(this);
		}
		return 0;
	}

	public function visitIf(stmt:StmtIf):Dynamic {
		stmt.ifClause.accept(this);
		if (stmt.elseIfClauses != null) {
			for (elseIfClause in stmt.elseIfClauses) {
				elseIfClause.accept(this);
			}
		}

		if (stmt.elseClause != null)
			stmt.elseClause.accept(this);
		return 0;
	}

	public function visitIfClause(stmt:StmtIfClause):Dynamic {
		stmt.expression.accept(this);
		for (statement in stmt.statements) {
			statement.accept(this);
		}
		return 0;
	}

	public function visitElseIfClause(stmt:StmtElseIfClause):Dynamic {
		stmt.expression.accept(this);
		for (statement in stmt.statements) {
			statement.accept(this);
		}

		return 0;
	}

	public function visitElseClause(stmt:StmtElseClause):Dynamic {
		for (statement in stmt.statements) {
			statement.accept(this);
		}

		return 0;
	}

	public function visitSet(stmt:StmtSet):Dynamic {
		stmt.expression.accept(this);
		return 0;
	}

	public function visitCall(stmt:StmtCall):Dynamic {
		stmt.functionCall.accept(this);
		return 0;
	}

	public function visitCommand(stmt:StmtCommand):Dynamic {
		stmt.formattedText.accept(this);
		for (hashtag in stmt.hashtags) {
			hashtag.accept(this);
		}
		return 0;
	}

	public function visitCommandFormattedText(stmt:StmtCommandFormattedText):Dynamic {
		for (child in stmt.children) {
			if (Std.isOfType(child, Expr))
				child.accept(this);
		}
		return 0;
	}

	public function visitShortcutOptionStatement(stmt:StmtShortcutOptionStatement):Dynamic {
		for (option in stmt.options) {
			option.accept(this);
		}

		return 0;
	}

	public function visitShortcutOption(stmt:StmtShortcutOption):Dynamic {
		stmt.lineStatement.accept(this);
		for (statement in stmt.statements) {
			statement.accept(this);
		}

		return 0;
	}

	public function visitDeclare(stmt:StmtDeclare):Dynamic {
		return stmt.value.accept(this);
	}

	public function visitJump(stmt:StmtJump):Dynamic {
		return stmt.stmt.accept(this);
	}

	public function visitExprParens(expr:ExprParens):Dynamic {
		return expr.expression.accept(this);
	}

	public function visitExprAssign(expr:ExprAssign):Dynamic {
		return expr.value.accept(this);
	}

	public function visitExprNegative(expr:ExprNegative):Dynamic {
		return expr.expression.accept(this);
	}

	public function visitExprNot(expr:ExprNot):Dynamic {
		return expr.expression.accept(this);
	}

	public function visitExprMultDivMod(expr:ExprMultDivMod):Dynamic {
		expr.left.accept(this);
		return expr.right.accept(this);
	}

	public function visitExprAddSub(expr:ExprAddSub):Dynamic {
		expr.left.accept(this);
		return expr.right.accept(this);
	}

	public function visitExprComparison(expr:ExprComparision):Dynamic {
		expr.left.accept(this);
		return expr.right.accept(this);
	}

	public function visitExprEquality(expr:ExprEquality):Dynamic {
		expr.left.accept(this);
		return expr.right.accept(this);
	}

	public function visitExprMultDivModEquals(expr:ExprMultDivModEquals):Dynamic {
		expr.left.accept(this);
		return 0;
	}

	public function visitExprPlusMinusEquals(expr:ExprPlusMinusEquals):Dynamic {
		return expr.left.accept(this);
	}

	public function visitExprAndOrXor(expr:ExprAndOrXor):Dynamic {
		expr.left.accept(this);
		return expr.right.accept(this);
	}

	public function visitExprValue(expr:ExprValue):Dynamic {
		return expr.value.accept(this);
	}

	public function visitValueNumber(value:ValueNumber):Dynamic {
		return 0;
	}

	public function visitValueTrue(value:ValueTrue):Dynamic {
		return 0;
	}

	public function visitValueFalse(value:ValueFalse):Dynamic {
		return 0;
	}

	public function visitValueVariable(value:ValueVariable):Dynamic {
		return 0;
	}

	public function visitValueString(value:ValueString):Dynamic {
		return 0;
	}

	public function visitValueNull(value:ValueNull):Dynamic {
		return 0;
	}

	public function visitValueFunctionCall(value:ValueFunctionCall):Dynamic {
		for (expr in value.expressions) {
			expr.accept(this);
		}
		return 0;
	}

	public function visitJumpToNodeName(stmt:StmtJumpToNodeName):Dynamic {
		return 0;
	}

	public function visitJumpToExpression(stmt:StmtJumpToExpression):Dynamic {
		return stmt.expr.accept(this);
	}
}
