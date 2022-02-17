package src.hxyarn.dialogue;

class StringInfo {
	public var text:String;
	public var fileName:String;
	public var nodeName:String;
	public var isImplicitTag:Bool;
	public var metadata:Array<String>;

	public function new(text:String, fileName:String, nodeName:String, lineNumber:Int, isImplicitTag:Bool, metadata:Array<String>) {
		this.text = text;
		this.fileName = fileName;
		this.nodeName = nodeName;
		this.isImplicitTag = isImplicitTag;

		if (metadata != null) {
			this.metadata = metadata;
		} else {
			this.metadata = new Array<String>();
		}
	}
}
