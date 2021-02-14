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
			type = Null;
			return;
		}

		if (Std.isOfType(value, Value)) {
			var otherValue = cast(value, Value);
			this.type = otherValue.type;
			switch (type) {
				case Number:
					this.numberValue = otherValue.numberValue;
				case String:
					this.stringValue = otherValue.stringValue;
				case Bool:
					this.boolValue = otherValue.boolValue;
				case Null:
				case _:
					throw new Exception('Cannot create new Value from Value with type of $type');
			}

			return;
		}

		if (Std.isOfType(value, String)) {
			type = String;
			stringValue = Std.string(value);
			return;
		}

		if (Std.isOfType(value, Int) || Std.isOfType(value, Float)) {
			type = Number;
			numberValue = cast(value, Float);
			return;
		}

		if (Std.isOfType(value, Bool)) {
			type = Bool;
			boolValue = cast(value, Bool);
			return;
		}

		throw new Exception('Attempted to create a Value using ${Type.getClassName(value)}');
	}

	public function asNumber():Float {
		switch (type) {
			case Number:
				return this.numberValue;
			case String:
				var parsedFloat = Std.parseFloat(this.stringValue);
				return parsedFloat;
			case Bool:
				return this.boolValue ? 1 : 0;
			case Null:
				return 0;
			case _:
				throw new Exception('Cannot cast to number from $type');
		}
	}

	public function asBool():Bool {
		switch (type) {
			case Number:
				return !Math.isNaN(this.numberValue) && this.numberValue != 0;
			case String:
				return !(this.stringValue == null || this.stringValue.length == 0);
			case Bool:
				return this.boolValue;
			case Null:
				return false;
			case _:
				throw new Exception('Cannot cast to bool from $type');
		}
	}

	public function asString():String {
		switch (type) {
			case Number:
				return Math.isNaN(this.numberValue) ? "NaN" : Std.string(this.numberValue);
			case String:
				return this.stringValue;
			case Bool:
				return Std.string(this.boolValue);
			case Null:
				return "null";
			case _:
				throw new Exception('Cannot cast to string from $type');
		}
	}

	function getValue():Dynamic {
		switch (this.type) {
			case Number:
				return this.numberValue;
			case String:
				return this.stringValue;
			case Bool:
				return this.boolValue;
			case Null:
				return null;
			case _:
		}
		throw new Exception('Couldn\'t get value for type $type');
	}

	public function add(b:Value) {
		var a = this;
		if (a.type == String || b.type == String) {
			return new Value(a.asString() + b.asString());
		}

		if ((a.type == Number || b.type == Number) || (a.type == Bool && b.type == Bool) || (a.type == Null && b.type == Null))
			return new Value(a.asNumber() + b.asNumber());

		throw new Exception('Cannot add types ${a.type} and ${b.type}.');
	}

	public function sub(b:Value) {
		var a = this;
		if (a.type == Number && (b.type == Number || b.type == Null) || b.type == Number && (a.type == Number || a.type == Null))
			return new Value(a.asNumber() - b.asNumber());

		throw new Exception('Cannot sub types ${a.type} and ${b.type}.');
	}

	public function div(b:Value) {
		var a = this;
		if (a.type == Number && (b.type == Number || b.type == Null) || b.type == Number && (a.type == Number || a.type == Null))
			return new Value(a.asNumber() / b.asNumber());

		throw new Exception('Cannot div types ${a.type} and ${b.type}.');
	}

	public function mul(b:Value) {
		var a = this;
		if (a.type == Number && (b.type == Number || b.type == Null) || b.type == Number && (a.type == Number || a.type == Null))
			return new Value(a.asNumber() * b.asNumber());

		throw new Exception('Cannot mul types ${a.type} and ${b.type}.');
	}

	public function mod(b:Value) {
		var a = this;
		if (a.type == Number && (b.type == Number || b.type == Null) || b.type == Number && (a.type == Number || a.type == Null))
			return new Value(a.asNumber() % b.asNumber());

		throw new Exception('Cannot mul types ${a.type} and ${b.type}.');
	}

	public function neg() {
		if (type == Number) {
			return new Value(-asNumber());
		}

		if (type == Null || type == String && (asString() == null || StringTools.trim(asString()).length <= 0))
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
				case Null:
					return 0;
				case String:
					return a.asString() < b.asString() ? -1 : a.asString() > b.asString() ? 1 : 0;
				case Number:
					return a.asNumber() < b.asNumber() ? -1 : a.asNumber() > b.asNumber() ? 1 : 0;
				case Bool:
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
			case Null:
				return other.type == Null || other.asNumber() == 0 || other.asBool() == false;
			case String:
				return this.asString() == other.asString();
			case Number:
				return this.asNumber() == other.asNumber();
			case Bool:
				return this.asBool() == other.asBool();
			case _:
				throw new Exception('Cannot compare type of ${type} to ${(other.type)}');
		}
	}
}

enum ValueType {
	Number;
	String;
	Bool;
	Variable;
	Null;
}
