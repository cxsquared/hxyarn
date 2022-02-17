package src.hxyarn.program.types;

import src.hxyarn.program.types.IType.MethodCollection;

class BooleanType extends TypeBase implements IBridgeableType<Bool> {
	public var defaultValue = false;

	public function new() {
		super(defaultMethods());
		name = "Bool";
		description = "bool";
	}

	public override function parent():IType {
		return BuiltInTypes.any;
	}

	public function toBridgedType(value:Value):Bool {
		return value.asBool();
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
			Operator.AND.getName() => {
				func: methodAnd,
				numberOfArgs: 2,
				returnType: BuiltInTypes.boolean
			},
			Operator.OR.getName() => {
				func: methodOr,
				numberOfArgs: 2,
				returnType: BuiltInTypes.boolean
			},
			Operator.NOT.getName() => {
				func: methodNot,
				numberOfArgs: 2,
				returnType: BuiltInTypes.boolean
			}
			// TODO: figure out Xor boolean
		];
	}

	private static function methodEqualTo(values:Array<Value>):Dynamic {
		return values[0].equals(values[1].asBool());
	}

	private static function methodNotEqualTo(values:Array<Value>):Dynamic {
		return !values[0].equals(values[1].asBool());
	}

	private static function methodAnd(values:Array<Value>):Dynamic {
		return values[0].asBool() && values[1].asBool();
	}

	private static function methodOr(values:Array<Value>):Dynamic {
		return values[0].asBool() || values[1].asBool();
	}

	private static function methodNot(values:Array<Value>):Dynamic {
		return !values[0].asBool();
	}

	public override function get_description():String {
		return "bool";
	}
}
