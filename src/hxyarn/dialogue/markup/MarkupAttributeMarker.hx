package hxyarn.dialogue.markup;

class MarkupAttributeMarker {
	public function new(name:String, position:Int, sourcePosition:Int, properties:Array<MarkupProperty>, type:TagType) {
		this.name = name;
		this.position = position;
		this.sourcePosition = sourcePosition;
		this.properties = properties;
		this.type = type;
	}

	public var name:String;
	public var position:Int;
	public var sourcePosition:Int;
	public var properties:Array<MarkupProperty>;
	public var type:TagType;

	public function tryGetProperty(name:String):MarkupValue {
		for (prop in properties) {
			if (prop.name == name) {
				return prop.value;
			}
		}

		return null;
	}
}

enum TagType {
	OPEN;
	CLOSE;
	SELFCLOSING;
	CLOSEALL;
}
