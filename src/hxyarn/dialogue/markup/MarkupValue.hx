package hxyarn.dialogue.markup;

class MarkupValue {
	public var integerValue:Int;
	public var floatValue:Float;
	public var stringValue:String;
	public var boolValue:Bool;
	public var type:MarkupValueType;

	public function new() {}

	public function toString():String {
		switch (type) {
			case INTEGER:
				return Std.string(integerValue);
			case FLOAT:
				return Std.string(floatValue);
			case STRING:
				return stringValue;
			case BOOL:
				return Std.string(boolValue);
			case _:
				throw 'Invalide type $type';
		}
	}
}

enum MarkupValueType {
	INTEGER;
	FLOAT;
	STRING;
	BOOL;
}
