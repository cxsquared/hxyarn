package hxyarn.program.types;

import hxyarn.program.types.IType.MethodCollection;

class NumberType extends TypeBase implements IBridgeableType<Float> {
	public var defaultValue = 0.0;

	public function new() {
		super(defaultMethods());
		name = "Number";
	}

	public override function parent():IType {
		return BuiltInTypes.any;
	}

	public function toBridgedType(value:Value):Float {
		return value.asNumber();
	}

	public override function defaultMethods():MethodCollection {
		return [
			Operator.EQUAL_TO.getName() => {
				func: methodEqualTo,
				numberOfArgs: 2,
				returnType: BuiltInTypes.boolean
			},
			Operator.NOT_EQUAL_TO.getName() => {
				func: methodNotEqualTo,
				numberOfArgs: 2,
				returnType: BuiltInTypes.boolean
			},
			Operator.ADD.getName() => {
				func: methodAdd,
				numberOfArgs: 2,
				returnType: BuiltInTypes.number
			},
			Operator.MINUS.getName() => {
				func: methodMinus,
				numberOfArgs: 2,
				returnType: BuiltInTypes.number
			},
			Operator.DIVIDE.getName() => {
				func: methodDivide,
				numberOfArgs: 2,
				returnType: BuiltInTypes.number
			},
			Operator.MULTIPLY.getName() => {
				func: methodMultiply,
				numberOfArgs: 2,
				returnType: BuiltInTypes.number
			},
			Operator.MODULO.getName() => {
				func: methodModulo,
				numberOfArgs: 2,
				returnType: BuiltInTypes.number
			},
			Operator.UNARY_MINUS.getName() => {
				func: methodUnaryMinus,
				numberOfArgs: 1,
				returnType: BuiltInTypes.number
			},
			Operator.GREATER_THAN.getName() => {
				func: methodGreaterThan,
				numberOfArgs: 2,
				returnType: BuiltInTypes.boolean
			},
			Operator.GREATER_THAN_OR_EQUAL_TO.getName() => {
				func: methodGreaterThanOrEqual,
				numberOfArgs: 2,
				returnType: BuiltInTypes.boolean
			},
			Operator.LESS_THAN.getName() => {
				func: methodLessThan,
				numberOfArgs: 2,
				returnType: BuiltInTypes.boolean
			},
			Operator.LESS_THAN_OR_EQUAL_TO.getName() => {
				func: methodLessThanOrEqual,
				numberOfArgs: 2,
				returnType: BuiltInTypes.boolean
			}
		];
	}

	private static function methodEqualTo(values:Array<Value>):Dynamic {
		return values[0].asNumber() == values[1].asNumber();
	}

	private static function methodNotEqualTo(values:Array<Value>):Dynamic {
		return values[0].asNumber() != values[1].asNumber();
	}

	private static function methodAdd(values:Array<Value>):Dynamic {
		return values[0].add(values[1]).asNumber();
	}

	private static function methodMinus(values:Array<Value>):Dynamic {
		return values[0].sub(values[1]).asNumber();
	}

	private static function methodDivide(values:Array<Value>):Dynamic {
		return values[0].div(values[1]).asNumber();
	}

	private static function methodMultiply(values:Array<Value>):Dynamic {
		return values[0].mul(values[1]).asNumber();
	}

	private static function methodModulo(values:Array<Value>):Dynamic {
		return values[0].mod(values[1]).asNumber();
	}

	private static function methodUnaryMinus(values:Array<Value>):Dynamic {
		return -values[0].asNumber();
	}

	private static function methodGreaterThan(values:Array<Value>):Dynamic {
		return values[0].greaterThan(values[1]);
	}

	private static function methodGreaterThanOrEqual(values:Array<Value>):Dynamic {
		return values[0].greatThanOrEqual(values[1]);
	}

	private static function methodLessThan(values:Array<Value>):Dynamic {
		return values[0].lessThan(values[1]);
	}

	private static function methodLessThanOrEqual(values:Array<Value>):Dynamic {
		return values[0].lessThanOrEqual(values[1]);
	}

	public override function get_description():String {
		return "number";
	}
}
