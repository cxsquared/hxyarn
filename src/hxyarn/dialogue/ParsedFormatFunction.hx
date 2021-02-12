package src.hxyarn.dialogue;

class ParsedFormatFunction {
	public var functionName:String;
	public var value:String;
	public var data:Map<String, String>;

	public function new(fn:String, v:String, d:Map<String, String>) {
		this.functionName = fn;
		this.value = v;
		this.data = d;
	}
}
