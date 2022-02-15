package src.hxyarn.compiler;

import src.hxyarn.program.Operator;
import src.hxyarn.compiler.Token.TokenType;

class OperatorUtils {
	public static var tokensToOperators = [
		TokenType.OPERATOR_LOGICAL_LESS_THAN_EQUALS => Operator.LESS_THAN_OR_EQUAL_TO,
		TokenType.OPERATOR_LOGICAL_GREATER_THAN_EQUALS => Operator.GREATER_THAN_OR_EQUAL_TO, TokenType.OPERATOR_LOGICAL_GREATER => Operator.GREATER_THAN,
		TokenType.OPERATOR_LOGICAL_LESS => Operator.LESS_THAN, TokenType.OPERATOR_LOGICAL_EQUALS => Operator.EQUAL_TO,
		TokenType.OPERATOR_LOGICAL_NOT_EQUALS => Operator.NOT_EQUAL_TO, TokenType.OPERATOR_LOGICAL_AND => Operator.AND,
		TokenType.OPERATOR_LOGICAL_OR => Operator.OR, TokenType.OPERATOR_LOGICAL_XOR => Operator.XOR, TokenType.OPERATOR_LOGICAL_NOT => Operator.NOT,
		TokenType.OPERATOR_MATHS_ADDITION => Operator.ADD, TokenType.OPERATOR_MATHS_SUBTRACTION => Operator.MINUS,
		TokenType.OPERATOR_MATHS_MULTIPLICATION => Operator.MULTIPLY, TokenType.OPERATOR_MATHS_DIVISION => Operator.DIVIDE,
		TokenType.OPERATOR_MATHS_MODULUS => Operator.MODULO
	];
}
