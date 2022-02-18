package hxyarn.dialogue;

class Command {
	public function new(text:String) {
		this.text = text;
	}

	public var text(default, set):String;

	function set_text(newText) {
		return text = newText;
	}
}
