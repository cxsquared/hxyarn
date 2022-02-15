package src.hxyarn.program.types;

import src.hxyarn.program.types.IType.MethodCollection;

class BooleanType extends TypeBase implements IBridgeableType<Bool> {
	public var defaultValue = false;

	public function new() {
		super(defaultMethods);
		name = "Bool";
		parent = BuiltInTypes.any;
		description = "bool";
	}

	public function toBridgedType(value:Value):Bool {
		return value.asBool();
	}

	private static var defaultMethods:MethodCollection = [
		Operator.EQUAL_TO.getName() => methodEqualTo,
		Operator.NOT_EQUAL_TO.getName() => methodNotEqualTo,
		Operator.AND.getName() => methodAnd,
		Operator.OR.getName() => methodOr,
		Operator.NOT.getName() => methodNot,
		// TODO: figure out Xor boolean
	];

	private static function methodEqualTo(a:Value, b:Value):Bool {
		return a.equals(b);
	}

	private static function methodNotEqualTo(a:Value, b:Value):Bool {
		return !a.equals(b);
	}

	private static function methodAnd(a:Value, b:Value):Bool {
		return a.asBool() && b.asBool();
	}

	private static function methodOr(a:Value, b:Value):Bool {
		return a.asBool() || b.asBool();
	}

	private static function methodNot(a:Value):Bool {
		return !a.asBool();
	}

	public override function get_description():String {
		return "bool";
	}
}
