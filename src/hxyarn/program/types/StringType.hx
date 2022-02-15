package src.hxyarn.program.types;

import src.hxyarn.program.types.IType.MethodCollection;
import src.hxyarn.program.Operator;

class StringType extends TypeBase implements IBridgeableType<String> {
	public var defaultValue = "";

	public function new() {
		super(defaultMethods);
		name = "String";
		parent = BuiltInTypes.any;
	}

	public function toBridgedType(value:Value):String {
		return value.asString();
	}

	private static var defaultMethods:MethodCollection = [
		Operator.EQUAL_TO.getName() => methodEqualTo,
		Operator.NOT_EQUAL_TO.getName() => methodNotEqualTo,
		Operator.ADD.getName() => methodAdd,
	];

	private static function methodEqualTo(a:Value, b:Value):Bool {
		return a.equals(b);
	}

	private static function methodNotEqualTo(a:Value, b:Value):Bool {
		return !a.equals(b);
	}

	private static function methodAdd(a:Value, b:Value):String {
		return a.asString() + b.asString();
	}

	public override function get_description():String {
		return "string";
	}
}
