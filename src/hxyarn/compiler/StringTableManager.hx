package src.hxyarn.compiler;

class StringTableManager {
	var stringTable = new Map<String, StringInfo>();

	public function new() {}

	function containsImplicitStringTags():Bool {
		for (item in stringTable) {
			if (item.isImplicitTag)
				return true;
		}

		return false;
	}

	public function registerString(text:String, fileName:String, nodeName:String, lineId:String, lineNumber:Int, tags:Array<String>):String {
		var lineIdUsed:String;
		var isImplicit:Bool;

		if (lineId == null || lineId == "") {
			var count = 0;
			for (key in stringTable.keys())
				count++;

			lineIdUsed = 'line:$fileName-$nodeName-$count';
			isImplicit = true;
		} else {
			lineIdUsed = lineId;
			isImplicit = false;
		}

		var theString = new StringInfo(text, fileName, nodeName, lineNumber, isImplicit, tags);

		stringTable.set(lineIdUsed, theString);

		return lineIdUsed;
	}
}
