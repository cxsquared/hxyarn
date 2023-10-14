package hxyarn.compiler;

class YarnStringTools {
	// Taken from StringTools
	public static inline var MIN_SURROGATE_CODE_POINT = 65536;

	// Taken from StringTools
	public static inline function utf16CodePointAt(s:String, index:Int):Int {
		var c = StringTools.fastCodeAt(s, index);
		if (c >= 0xD800 && c <= 0xDBFF) {
			c = ((c - 0xD7C0) << 10) | (StringTools.fastCodeAt(s, index + 1) & 0x3FF);
		}
		return c;
	}
}
