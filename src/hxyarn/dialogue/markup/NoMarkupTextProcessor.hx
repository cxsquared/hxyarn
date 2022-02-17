package src.hxyarn.dialogue.markup;

class NoMarkupTextProcessor implements IAttributeMarkerProcessor {
	public function new() {}

	public function replacementTextForMarker(marker:MarkupAttributeMarker):String {
		var prop = marker.tryGetProperty(LineParser.ReplacementMarkerContents);
		if (prop != null) {
			return prop.stringValue;
		}

		return "";
	}
}
