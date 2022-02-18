package hxyarn.dialogue.markup;

class MarkupProperty {
	public function new(name:String, value:MarkupValue) {
		this.name = name;
		this.value = value;
	}

	public var name:String;
	public var value:MarkupValue;
}
