package src.hxyarn;

import haxe.Exception;

class Value {
	public static var NULL = new Value(null);

	public var type(default, set):ValueType;

	function set_type(newType) {
		return type = newType;
	}

	var numberValue:Float;
	var variableName:String;
	var stringValue:String;
	var boolValue:Bool;

	public function new(value:Dynamic) {
		if (value == null) {
			type = NullValue;
			return;
		}

		if (Std.isOfType(value, Value)) {
			var otherValue = cast(value, Value);
			this.type = otherValue.type;
			switch (type) {
				case NumberValue:
					this.numberValue = otherValue.numberValue;
				case StringValue:
					this.stringValue = otherValue.stringValue;
				case BoolValue:
					this.boolValue = otherValue.boolValue;
				case NullValue:
				case _:
					throw new Exception('Cannot create new Value from Value with type of $type');
			}

			return;
		}

		if (Std.isOfType(value, String)) {
			type = StringValue;
			stringValue = Std.string(value);
			return;
		}

		if (Std.isOfType(value, Int) || Std.isOfType(value, Float)) {
			type = NumberValue;
			numberValue = cast(value, Float);
			return;
		}

		if (Std.isOfType(value, Bool)) {
			type = BoolValue;
			boolValue = cast(value, Bool);
			return;
		}

		throw new Exception('Attempted to create a Value using ${Type.getClassName(value)}');
	}

	public function asNumber():Float {
		switch (type) {
			case NumberValue:
				return this.numberValue;
			case StringValue:
				var parsedFloat = Std.parseFloat(this.stringValue);
				return parsedFloat;
			case BoolValue:
				return this.boolValue ? 1 : 0;
			case NullValue:
				return 0;
			case _:
				throw new Exception('Cannot cast to number from $type');
		}
	}

	public function asBool():Bool {
		switch (type) {
			case NumberValue:
				return !Math.isNaN(this.numberValue) && this.numberValue != 0;
			case StringValue:
				return !(this.stringValue == null || this.stringValue.length == 0);
			case BoolValue:
				return this.boolValue;
			case NullValue:
				return false;
			case _:
				throw new Exception('Cannot cast to bool from $type');
		}
	}

	public function asString():String {
		switch (type) {
			case NumberValue:
				return Math.isNaN(this.numberValue) ? "NaN" : Std.string(this.numberValue);
			case StringValue:
				return this.stringValue;
			case BoolValue:
				return Std.string(this.boolValue);
			case NullValue:
				return "null";
			case _:
				throw new Exception('Cannot cast to string from $type');
		}
	}

	function getValue():Dynamic {
		switch (this.type) {
			case NumberValue:
				return this.numberValue;
			case StringValue:
				return this.stringValue;
			case BoolValue:
				return this.boolValue;
			case NullValue:
				return null;
			case _:
		}
		throw new Exception('Couldn\'t get value for type $type');
	}

	public function add(b:Value) {
		var a = this;
		if (a.type == StringValue || b.type == StringValue) {
			return new Value(a.asString() + b.asString());
		}

		if ((a.type == NumberValue || b.type == NumberValue)
			|| (a.type == BoolValue && b.type == BoolValue)
			|| (a.type == NullValue && b.type == NullValue))
			return new Value(a.asNumber() + b.asNumber());

		throw new Exception('Cannot add types ${a.type} and ${b.type}.');
	}

	public function sub(b:Value) {
		var a = this;
		if (a.type == NumberValue
			&& (b.type == NumberValue || b.type == NullValue)
			|| b.type == NumberValue
			&& (a.type == NumberValue || a.type == NullValue))
			return new Value(a.asNumber() - b.asNumber());

		throw new Exception('Cannot sub types ${a.type} and ${b.type}.');
	}

	public function div(b:Value) {
		var a = this;
		if (a.type == NumberValue
			&& (b.type == NumberValue || b.type == NullValue)
			|| b.type == NumberValue
			&& (a.type == NumberValue || a.type == NullValue))
			return new Value(a.asNumber() / b.asNumber());

		throw new Exception('Cannot div types ${a.type} and ${b.type}.');
	}

	public function mul(b:Value) {
		var a = this;
		if (a.type == NumberValue
			&& (b.type == NumberValue || b.type == NullValue)
			|| b.type == NumberValue
			&& (a.type == NumberValue || a.type == NullValue))
			return new Value(a.asNumber() * b.asNumber());

		throw new Exception('Cannot mul types ${a.type} and ${b.type}.');
	}

	public function mod(b:Value) {
		var a = this;
		if (a.type == NumberValue
			&& (b.type == NumberValue || b.type == NullValue)
			|| b.type == NumberValue
			&& (a.type == NumberValue || a.type == NullValue))
			return new Value(a.asNumber() % b.asNumber());

		throw new Exception('Cannot mul types ${a.type} and ${b.type}.');
	}

	public function neg() {
		if (type == NumberValue) {
			return new Value(-asNumber());
		}

		if (type == NullValue || type == StringValue && (asString() == null || StringTools.trim(asString()).length <= 0))
			return new Value(-0);

		return new Value(Math.NaN);
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
			switch (a.type) {
				case NullValue:
					return 0;
				case StringValue:
					return a.asString() < b.asString() ? -1 : a.asString() > b.asString() ? 1 : 0;
				case NumberValue:
					return a.asNumber() < b.asNumber() ? -1 : a.asNumber() > b.asNumber() ? 1 : 0;
				case BoolValue:
					return a.asBool() == b.asBool() ? 0 : 1;
				case _:
					throw new Exception('Cannot compare type of ${a.type} to ${b.type}');
			}
		}

		return a.asString() < b.asString() ? -1 : a.asString() > b.asString() ? 1 : 0;
	}

	public function equals(obj:Dynamic) {
		if (obj == null || !Std.isOfType(obj, Value))
			return false;

		var other = cast(obj, Value);

		switch (this.type) {
			case NullValue:
				return other.type == NullValue || other.asNumber() == 0 || other.asBool() == false;
			case StringValue:
				return this.asString() == other.asString();
			case NumberValue:
				return this.asNumber() == other.asNumber();
			case BoolValue:
				return this.asBool() == other.asBool();
			case _:
				throw new Exception('Cannot compare type of ${type} to ${(other.type)}');
		}
	}
}

enum ValueType {
	NumberValue;
	StringValue;
	BoolValue;
	VariableValue;
	NullValue;
}
