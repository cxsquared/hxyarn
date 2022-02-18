package hxyarn.program.types;

import hxyarn.program.types.IType.MethodCollection;
import hxyarn.program.Operator;

class StringType extends TypeBase implements IBridgeableType<String> {
	public var defaultValue = "";

	public function new() {
		super(defaultMethods());
		name = "String";
	}

	public override function parent():IType {
		return BuiltInTypes.any;
	}

	public function toBridgedType(value:Value):String {
		return value.asString();
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
				returnType: BuiltInTypes.string
			}
		];
	}

	private static function methodEqualTo(values:Array<Value>):Dynamic {
		return values[0].asString() == values[1].asString();
	}

	private static function methodNotEqualTo(values:Array<Value>):Dynamic {
		return values[0].asString() != values[1].asString();
	}

	private static function methodAdd(values:Array<Value>):Dynamic {
		return values[0].asString() + values[1].asString();
	}

	public override function get_description():String {
		return "string";
	}
}
