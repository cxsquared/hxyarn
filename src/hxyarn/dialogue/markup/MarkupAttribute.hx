package hxyarn.dialogue.markup;

class MarkupAttribute {
	public var position:Int;
	public var length:Int;
	public var name:String;
	public var properties:Array<MarkupProperty>;

	public var sourcePosition:Int;

	public static function createFromMarker(openingMarker:MarkupAttributeMarker, length:Int) {
		return new MarkupAttribute(openingMarker.position, openingMarker.sourcePosition, length, openingMarker.name, openingMarker.properties);
	}

	public function new(position:Int, sourcePosition:Int, length:Int, name:String, properties:Array<MarkupProperty>) {
		this.position = position;
		this.sourcePosition = sourcePosition;
		this.length = length;
		this.name = name;
		this.properties = properties;
	}

	public function toString():String {
		var sb = new StringBuf();
		sb.add('[$name] - $position-${position + length} ($length');

		if (properties != null && properties.length > 0) {
			sb.add(', ${properties.length} properties)');
		}

		sb.add(')');

		return sb.toString();
	}
}
