package src.hxyarn.program.types;

import src.hxyarn.program.types.IType.MethodCollection;

class NumberType extends TypeBase implements IBridgeableType<Float> {
	public var defaultValue = 0.0;

	public function new() {
		super(defaultMethods);
		name = "Number";
		parent = BuiltInTypes.any;
	}

	public function toBridgedType(value:Value):Float {
		return value.asNumber();
	}

	private static var defaultMethods:MethodCollection = [
		Operator.EQUAL_TO.getName() => methodEqualTo, Operator.NOT_EQUAL_TO.getName() => methodNotEqualTo, Operator.ADD.getName() => methodAdd,
		Operator.MINUS.getName() => methodMinus, Operator.DIVIDE.getName() => methodDivide, Operator.MULTIPLY.getName() => methodMultiply,
		Operator.MODULO.getName() => methodModulo, Operator.UNARY_MINUS.getName() => methodUnaryMinus, Operator.GREATER_THAN.getName() => methodGreaterThan,
		Operator.GREATER_THAN_OR_EQUAL_TO.getName() => methodGreaterThanOrEqual, Operator.LESS_THAN.getName() => methodLessThan,
		Operator.LESS_THAN_OR_EQUAL_TO.getName() => methodLessThanOrEqual
	];

	private static function methodEqualTo(a:Value, b:Value):Bool {
		return a.equals(b);
	}

	private static function methodNotEqualTo(a:Value, b:Value):Bool {
		return !a.equals(b);
	}

	private static function methodAdd(a:Value, b:Value):Float {
		return a.add(b).asNumber();
	}

	private static function methodMinus(a:Value, b:Value):Float {
		return a.sub(b).asNumber();
	}

	private static function methodDivide(a:Value, b:Value):Float {
		return a.div(b).asNumber();
	}

	private static function methodMultiply(a:Value, b:Value):Float {
		return a.mul(b).asNumber();
	}

	private static function methodModulo(a:Value, b:Value):Float {
		return a.mod(b).asNumber();
	}

	private static function methodUnaryMinus(a:Value):Float {
		return -a.asNumber();
	}

	private static function methodGreaterThan(a:Value, b:Value):Bool {
		return a.greaterThan(b);
	}

	private static function methodGreaterThanOrEqual(a:Value, b:Value):Bool {
		return a.greatThanOrEqual(b);
	}

	private static function methodLessThan(a:Value, b:Value):Bool {
		return a.lessThan(b);
	}

	private static function methodLessThanOrEqual(a:Value, b:Value):Bool {
		return a.lessThanOrEqual(b);
	}

	public override function get_description():String {
		return "number";
	}
}
