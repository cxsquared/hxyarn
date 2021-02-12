package src.hxyarn.dialogue;

class Line {
	public var id:String;
	public var substitutions:Array<String>;

	public function new(id:String) {
		this.id = id;
		this.substitutions = new Array<String>();
	}
}
