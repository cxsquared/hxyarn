package src.hxyarn.compiler;

import src.hxyarn.compiler.Stmt.StmtJumpToExpression;
import src.hxyarn.program.types.TypeUtils;
import src.hxyarn.compiler.Stmt.StmtElseIfClause;
import src.hxyarn.compiler.Stmt.StmtIfClause;
import src.hxyarn.compiler.Stmt.StmtJump;
import src.hxyarn.compiler.Stmt.StmtLineFormattedText;
import src.hxyarn.compiler.Expr.ExprNot;
import src.hxyarn.compiler.Expr.ExprNegative;
import src.hxyarn.compiler.Expr.ExprEquality;
import src.hxyarn.compiler.Expr.ExprComparision;
import src.hxyarn.compiler.Expr.ExprMultDivMod;
import src.hxyarn.compiler.Expr.ExprAddSub;
import src.hxyarn.program.types.FunctionType;
import src.hxyarn.compiler.Value.ValueFalse;
import src.hxyarn.program.types.BuiltInTypes;
import src.hxyarn.program.types.IType;
import src.hxyarn.compiler.Value.ValueVariable;
import src.hxyarn.program.Operator;
import src.hxyarn.compiler.Expr.ExprAndOrXor;
import src.hxyarn.compiler.Expr.ExprParens;
import src.hxyarn.compiler.Value.ValueFunctionCall;
import src.hxyarn.compiler.Value.ValueNumber;
import src.hxyarn.compiler.Value.ValueTrue;
import src.hxyarn.compiler.Value.ValueString;
import src.hxyarn.compiler.Value.ValueNull;
import src.hxyarn.compiler.Expr.ExprValue;
import src.hxyarn.compiler.Stmt.StmtNode;
import src.hxyarn.compiler.Declaration;

class TypeCheckVisitor extends BaseVisitor {
	var currentNodeName:String = null;
	var sourceFileName:String;
	var existingDeclarations:Array<Declaration>;
	var newDeclarations:Array<Declaration>;
	var types:Array<IType>;
	var currentNodeContext:StmtNode;

	public function declarations():Array<Declaration> {
		return this.existingDeclarations.concat(this.newDeclarations);
	}

	public function new(sourceFileName:String, existingDeclarations:Array<Declaration>, types:Array<IType>) {
		this.sourceFileName = sourceFileName;
		this.existingDeclarations = existingDeclarations;
		this.newDeclarations = new Array<Declaration>();
		this.types = types;
	}

	public override function visitNode(stmt:StmtNode):Dynamic {
		currentNodeContext = stmt;
		for (header in stmt.headers) {
			if (header.id.lexeme == "title")
				currentNodeName = header.value.lexeme;
		}

		var body = stmt.body;

		if (body != null)
			visitBody(body);

		return null;
	}

	public override function visitValueNull(value:ValueNull):Dynamic {
		return BuiltInTypes.undefined;
	}

	public override function visitValueString(value:ValueString):Dynamic {
		return BuiltInTypes.string;
	}

	public override function visitValueTrue(value:ValueTrue):Dynamic {
		return BuiltInTypes.boolean;
	}

	public override function visitValueFalse(value:ValueFalse):Dynamic {
		return BuiltInTypes.boolean;
	}

	public override function visitValueNumber(value:ValueNumber):Dynamic {
		return BuiltInTypes.number;
	}

	public override function visitValueVariable(stmt:ValueVariable):Dynamic {
		var name = stmt.varId.lexeme;

		if (name == null || name == "")
			return BuiltInTypes.undefined;

		for (declaration in declarations()) {
			if (declaration.name == name) {
				return declaration.type;
			}
		}

		return BuiltInTypes.undefined;
	}

	public override function visitValueFunctionCall(value:ValueFunctionCall):Dynamic {
		var functionName = value.functionId.lexeme;

		var functionDeclarationList = declarations().filter(function(d:Declaration) {
			return Std.isOfType(d.type, FunctionType);
		}).filter(function(d:Declaration) {
			return d.name == functionName;
		});

		var functionDeclaration:Declaration = null;

		if (functionDeclarationList.length > 0) {
			functionDeclaration = functionDeclarationList[0];
		}

		var functionType:FunctionType = null;

		if (functionDeclaration == null) {
			functionType = new FunctionType();
			functionType.returnType = BuiltInTypes.undefined;

			functionDeclaration = new Declaration();
			functionDeclaration.name = functionName;
			functionDeclaration.type = functionType;
			functionDeclaration.isImplicit = true;
			functionDeclaration.description = 'Implicit declaration of function at $sourceFileName: ${value.functionId.line}';
			functionDeclaration.sourceFileName = sourceFileName;
			functionDeclaration.sourceFileLine = value.functionId.line;
			functionDeclaration.sourceNodeName = currentNodeName;

			var parameterTypes = value.expressions.map(function(e:Expr) {
				return BuiltInTypes.undefined;
			});

			for (parameterType in parameterTypes) {
				functionType.parameters.push(parameterType);
			}

			newDeclarations.push(functionDeclaration);
		} else {
			functionType = cast(functionDeclaration.type, FunctionType);
		}

		// TODO type check parameters of function
		var suppliedParameters = value.expressions;
		var expectedParameters = functionType.parameters;

		if (suppliedParameters.length != expectedParameters.length) {
			// TODO diagnostics
			return functionType.returnType;
		}

		for (i in 0...expectedParameters.length) {
			var suppliedParameter = suppliedParameters[i];
			var expectedType = expectedParameters[i];

			var suppliedtype = suppliedParameter.accept(this);

			if (expectedType == BuiltInTypes.undefined) {
				expectedParameters[i] = suppliedtype;
				expectedType = suppliedtype;
			}

			if (TypeUtils.isSubType(expectedType, suppliedtype) == false) {
				// TODO diagnostics
				return functionType.returnType;
			}
		}

		return functionType.returnType;
	}

	public override function visitExprValue(expr:ExprValue):Dynamic {
		var type = expr.value.accept(this);
		expr.type = type;
		return type;
	}

	public override function visitExprParens(expr:ExprParens):Dynamic {
		var type = expr.expression.accept(this);
		expr.type = type;
		return type;
	}

	public override function visitExprAndOrXor(expr:ExprAndOrXor):Dynamic {
		var type = checkOperation(expr, [expr.left, expr.right], OperatorUtils.tokensToOperators[expr.op.type], expr.op.lexeme);
		expr.type = type;
		return type;
	}

	public override function visitExprAddSub(expr:ExprAddSub):Dynamic {
		var type = checkOperation(expr, [expr.left, expr.right], OperatorUtils.tokensToOperators[expr.op.type], expr.op.lexeme);
		expr.type = type;
		return type;
	}

	public override function visitExprMultDivMod(expr:ExprMultDivMod):Dynamic {
		var type = checkOperation(expr, [expr.left, expr.right], OperatorUtils.tokensToOperators[expr.op.type], expr.op.lexeme);
		expr.type = type;
		return type;
	}

	public override function visitExprComparison(expr:ExprComparision):Dynamic {
		var type = checkOperation(expr, [expr.left, expr.right], OperatorUtils.tokensToOperators[expr.op.type], expr.op.lexeme);
		expr.type = type;

		return BuiltInTypes.boolean;
	}

	public override function visitExprEquality(expr:ExprEquality):Dynamic {
		var type = checkOperation(expr, [expr.left, expr.right], OperatorUtils.tokensToOperators[expr.op.type], expr.op.lexeme);
		expr.type = type;

		return BuiltInTypes.boolean;
	}

	public override function visitExprNegative(expr:ExprNegative):Dynamic {
		var type = checkOperation(expr, [expr.expression], Operator.UNARY_MINUS, "-");
		expr.type = type;

		return type;
	}

	public override function visitExprNot(expr:ExprNot):Dynamic {
		var type = checkOperation(expr, [expr.expression], Operator.NOT, "!");
		expr.type = type;

		return type;
	}

	public override function visitLineFormattedText(stmt:StmtLineFormattedText):Dynamic {
		for (expr in stmt.expressions()) {
			var type = checkOperation(expr, [expr], Operator.NONE, "inline expression", [BuiltInTypes.any]);
			expr.type = type;
		}

		return BuiltInTypes.string;
	}

	public override function visitJumpToExpression(stmt:StmtJumpToExpression):Dynamic {
		return checkOperation(stmt, [stmt.expr], Operator.NONE, "jump statement", [BuiltInTypes.string]);
	}

	public override function visitIfClause(stmt:StmtIfClause):Dynamic {
		for (child in stmt.statements) {
			child.accept(this);
		}

		var expressions = [stmt.expression];
		return checkOperation(stmt, expressions, Operator.NONE, "if staement", [BuiltInTypes.boolean]);
	}

	public override function visitElseIfClause(stmt:StmtElseIfClause):Dynamic {
		for (child in stmt.statements) {
			child.accept(this);
		}

		var expressions = [stmt.expression];
		return checkOperation(stmt, expressions, Operator.NONE, "elseif staement", [BuiltInTypes.boolean]);
	}

	function checkOperation(context:Dynamic, terms:Array<Expr>, operationType:Operator, operationDescription:String, ?permittedTypes:Array<IType>):IType {
		var termTypes = new Array<IType>();
		if (permittedTypes == null)
			permittedTypes = new Array<IType>();

		var expressionType = BuiltInTypes.undefined;

		for (term in terms) {
			var type = term.accept(this);

			if (type != BuiltInTypes.undefined) {
				termTypes.push(type);
				if (expressionType == BuiltInTypes.undefined) {
					expressionType = type;
				}
			}
		}

		if (permittedTypes.length == 1 && expressionType == BuiltInTypes.undefined) {
			expressionType = permittedTypes[0];
		}

		if (expressionType == BuiltInTypes.undefined) {
			var typesImplementingMethod = types.filter(function(t:IType) {
				return t.methods != null && t.methods.exists(operationType.getName());
			});

			if (typesImplementingMethod.length == 1) {
				expressionType = typesImplementingMethod[0];
			} else if (typesImplementingMethod.length > 1) {
				// TODO better error message
				return BuiltInTypes.undefined;
			}
			// TODO better error message
			return BuiltInTypes.undefined;
		}

		var variableName = terms.map(function(e:Expr):ValueVariable {
			return e.getChild(ValueVariable);
		}).filter(function(v:ValueVariable):Bool {
			return v != null;
		}).map(function(v:ValueVariable):String {
			return v.varId.lexeme;
		});

		var undefinedVariables = variableName.filter(function(v:String):Bool {
			return declarations().filter(function(d:Declaration):Bool {
				return d.name == v;
			}).length <= 0;
		});

		if (undefinedVariables.length > 0) {
			var positionInfile = 0; // TODO
			var nodePositionInFile = 0; // TODO

			for (undefinedVariableName in undefinedVariables) {
				var decl = new Declaration();
				decl.name = undefinedVariableName;
				decl.description = '$sourceFileName, node $currentNodeName, line ${positionInfile - nodePositionInFile}';
				decl.type = expressionType;
				decl.defaultValue = defaultValueForType(expressionType);
				decl.sourceFileName = sourceFileName;
				decl.sourceFileLine = positionInfile;
				decl.sourceNodeName = currentNodeName;
				decl.sourceNodeLine = nodePositionInFile;
				decl.isImplicit = true;

				newDeclarations.push(decl);
			}
		}

		var invalidTermTypes = termTypes.filter(function(t:IType):Bool {
			return t == expressionType;
		}).length != termTypes.length;

		if (invalidTermTypes) {
			// TODO logging
			return BuiltInTypes.undefined;
		}

		for (term in terms) {
			if (term.type == BuiltInTypes.undefined) {
				term.type = expressionType;
			}

			if (Std.isOfType(term.type, FunctionType) && cast(term.type, FunctionType).returnType == BuiltInTypes.undefined) {
				cast(term.type, FunctionType).returnType = expressionType;
			}
		}

		if (operationType != Operator.NONE) {
			var implmentingType = TypeUtils.findImplementingTypeForMethod(expressionType, operationType.getName());

			if (implmentingType == null) {
				// TODO loggin
				return BuiltInTypes.undefined;
			}
		}

		if (permittedTypes.length > 0) {
			var isPermittedType = permittedTypes.filter(function(t:IType) {
				return TypeUtils.isSubType(t, expressionType);
			}).length > 0;

			if (isPermittedType)
				return expressionType;

			// TODO loggin
			return BuiltInTypes.undefined;
		}

		var implentingType = TypeUtils.findImplementingTypeForMethod(expressionType, operationType.getName());

		if (implentingType == null) {
			// TODO loggin
			return BuiltInTypes.undefined;
		}

		return expressionType;
	}

	function defaultValueForType(expressionType:IType):Dynamic {
		if (expressionType == BuiltInTypes.string) {
			return "";
		}

		if (expressionType == BuiltInTypes.boolean) {
			return false;
		}

		if (expressionType == BuiltInTypes.number) {
			return 0;
		}

		throw 'No default value for ${expressionType.name} exists.';
	}
}
