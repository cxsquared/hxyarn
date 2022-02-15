package src.hxyarn.program;

import src.hxyarn.program.types.BuiltInTypes;
import src.hxyarn.program.types.IType;
import haxe.Exception;

class Value {
	public static var NULL = new Value(null, BuiltInTypes.undefined);

	public var type(default, null):IType;

	public var internalValue:Dynamic;

	public function new(literal:Dynamic, type:IType) {
		this.type = type;
		this.internalValue = literal;
	}

	public function asNumber():Float {
		if (type == BuiltInTypes.number)
			return cast(internalValue, Float);

		if (type == BuiltInTypes.string)
			return Std.parseFloat(internalValue);

		if (type == BuiltInTypes.boolean)
			return cast(internalValue, Bool) ? 1 : 0;

		if (type == BuiltInTypes.undefined)
			return 0;

		throw new Exception('Cannot cast to number from $type');
	}

	public function asBool():Bool {
		if (type == BuiltInTypes.boolean)
			return cast(internalValue, Bool);

		if (type == BuiltInTypes.number) {
			var numberValue = Std.parseFloat(internalValue);
			return !Math.isNaN(numberValue) && numberValue != 0;
		}

		if (type == BuiltInTypes.string) {
			var stringValue = Std.string(internalValue);
			return !(stringValue == null || stringValue.length == 0);
		}

		if (type == BuiltInTypes.undefined)
			return false;

		throw new Exception('Cannot cast to bool from $type');
	}

	public function asString():String {
		if (type == BuiltInTypes.string)
			return Std.string(internalValue);

		if (type == BuiltInTypes.number) {
			var numberValue = Std.parseFloat(internalValue);
			return Math.isNaN(numberValue) ? "NaN" : Std.string(numberValue);
		}

		if (type == BuiltInTypes.boolean)
			return cast(internalValue, Bool) ? "True" : "False";

		if (type == BuiltInTypes.undefined)
			return "null";

		throw new Exception('Cannot cast to string from $type');
	}

	function getValue():Dynamic {
		if (type == BuiltInTypes.number)
			return Std.parseFloat(internalValue);

		if (type == BuiltInTypes.boolean)
			return cast(internalValue, Bool);

		if (type == BuiltInTypes.string)
			return Std.string(internalValue);

		if (type == BuiltInTypes.undefined)
			return null;

		throw new Exception('Couldn\'t get value for type $type');
	}

	public function add(b:Value) {
		var a = this;
		if (a.type == BuiltInTypes.string || b.type == BuiltInTypes.string) {
			return new Value(a.asString() + b.asString(), BuiltInTypes.string);
		}

		if ((a.type == BuiltInTypes.number || b.type == BuiltInTypes.number)
			|| (a.type == BuiltInTypes.boolean && b.type == BuiltInTypes.boolean)
			|| (a.type == BuiltInTypes.undefined && b.type == BuiltInTypes.undefined))
			return new Value(a.asNumber() + b.asNumber(), BuiltInTypes.number);

		throw new Exception('Cannot add types ${a.type} and ${b.type}.');
	}

	public function sub(b:Value) {
		var a = this;
		if (a.type == BuiltInTypes.number
			&& (b.type == BuiltInTypes.number || b.type == BuiltInTypes.undefined)
			|| b.type == BuiltInTypes.number
			&& (a.type == BuiltInTypes.number || a.type == BuiltInTypes.undefined))
			return new Value(a.asNumber() - b.asNumber(), BuiltInTypes.number);

		throw new Exception('Cannot sub types ${a.type} and ${b.type}.');
	}

	public function div(b:Value) {
		var a = this;
		if (a.type == BuiltInTypes.number
			&& (b.type == BuiltInTypes.number || b.type == BuiltInTypes.undefined)
			|| b.type == BuiltInTypes.number
			&& (a.type == BuiltInTypes.number || a.type == BuiltInTypes.undefined))
			return new Value(a.asNumber() / b.asNumber(), BuiltInTypes.number);

		throw new Exception('Cannot div types ${a.type} and ${b.type}.');
	}

	public function mul(b:Value) {
		var a = this;
		if (a.type == BuiltInTypes.number
			&& (b.type == BuiltInTypes.number || b.type == BuiltInTypes.undefined)
			|| b.type == BuiltInTypes.number
			&& (a.type == BuiltInTypes.number || a.type == BuiltInTypes.undefined))
			return new Value(a.asNumber() * b.asNumber(), BuiltInTypes.number);

		throw new Exception('Cannot mul types ${a.type} and ${b.type}.');
	}

	public function mod(b:Value) {
		var a = this;
		if (a.type == BuiltInTypes.number
			&& (b.type == BuiltInTypes.number || b.type == BuiltInTypes.undefined)
			|| b.type == BuiltInTypes.number
			&& (a.type == BuiltInTypes.number || a.type == BuiltInTypes.undefined))
			return new Value(a.asNumber() % b.asNumber(), BuiltInTypes.number);

		throw new Exception('Cannot mul types ${a.type} and ${b.type}.');
	}

	public function neg() {
		if (type == BuiltInTypes.number) {
			return new Value(-asNumber(), BuiltInTypes.number);
		}

		if (type == BuiltInTypes.undefined
			|| type == BuiltInTypes.string
			&& (asString() == null || StringTools.trim(asString()).length <= 0))
			return new Value(-0, BuiltInTypes.number);

		return new Value(Math.NaN, BuiltInTypes.number);
	}

	public function greaterThan(b:Value) {
		return this.compareTo(b) == 1;
	}

	public function lessThan(b:Value) {
		return this.compareTo(b) == -1;
	}

	public function greatThanOrEqual(b:Value) {
		return this.compareTo(b) >= 0;
	}

	public function lessThanOrEqual(b:Value) {
		return this.compareTo(b) <= 0;
	}

	function compareTo(b:Value) {
		var a = this;

		if (a == null) {
			return 1;
		}

		if (a.type == b.type) {
			if (a.type == BuiltInTypes.number)
				return a.asNumber() < b.asNumber() ? -1 : a.asNumber() > b.asNumber() ? 1 : 0;

			if (a.type == BuiltInTypes.string)
				return a.asString() < b.asString() ? -1 : a.asString() > b.asString() ? 1 : 0;

			if (a.type == BuiltInTypes.boolean)
				return a.asBool() == b.asBool() ? 0 : 1;

			if (a.type == BuiltInTypes.undefined)
				return 0;

			throw new Exception('Cannot compare type of ${a.type} to ${b.type}');
		}

		return a.asString() < b.asString() ? -1 : a.asString() > b.asString() ? 1 : 0;
	}

	public function equals(obj:Dynamic) {
		if (obj == null || !Std.isOfType(obj, Value))
			return false;

		var other = cast(obj, Value);

		if (type == BuiltInTypes.undefined)
			return other.type == BuiltInTypes.undefined || other.asNumber() == 0 || other.asBool() == false;

		if (type == BuiltInTypes.number)
			return this.asNumber() == other.asNumber();

		if (type == BuiltInTypes.string)
			return this.asString() == other.asString();

		if (type == BuiltInTypes.boolean)
			return this.asBool() == other.asBool();

		throw new Exception('Cannot compare type of ${type} to ${(other.type)}');
	}
}
