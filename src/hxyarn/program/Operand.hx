package hxyarn.program;

class Operand {
	public var stringValue:String;
	public var boolValue:Bool;
	public var floatValue:Float;
	public var type:OperandType;

	public function new(type:OperandType) {
		this.type = type;
	}

	public static function fromBool(value:Bool):Operand {
		var op = new Operand(BOOL);
		op.boolValue = value;
		return op;
	}

	public static function fromString(value:String):Operand {
		var op = new Operand(STRING);
		op.stringValue = value;
		return op;
	}

	public static function fromFloat(value:Float):Operand {
		var op = new Operand(FLOAT);
		op.floatValue = value;
		return op;
	}
}

enum OperandType {
	STRING;
	BOOL;
	FLOAT;
}
