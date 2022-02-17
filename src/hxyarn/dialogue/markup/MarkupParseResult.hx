package src.hxyarn.dialogue.markup;

class MarkupParseResult {
	public var text:String;
	public var attributes:Array<MarkupAttribute>;

	public function new(text:String, attributes:Array<MarkupAttribute>) {
		this.text = text;
		this.attributes = attributes;
	}

	public function tryGetAttributeWithName(name:String):MarkupAttribute {
		for (a in attributes) {
			if (a.name == name)
				return a;
		}

		return null;
	}

	public function textForAttribute(attribute:MarkupAttribute):String {
		if (attribute.length == 0)
			return "";

		if (text.length < attribute.position + attribute.length)
			throw 'Attribute represents a range not representable by this text. Does this MarkupAttribute belong to this MarkupParseResult?';

		return this.text.substr(attribute.position, attribute.length);
	}

	public function deleteRange(attributeToDelete:MarkupAttribute):MarkupParseResult {
		var newAttributes = new Array<MarkupAttribute>();

		if (attributeToDelete.length == 0) {
			for (a in attributes) {
				if (a != attributeToDelete)
					newAttributes.push(a);
			}

			return new MarkupParseResult(text, newAttributes);
		}

		var deletionStart = attributeToDelete.position;
		var deletionEnd = attributeToDelete.position + attributeToDelete.length;

		var editedSubString = this.text.substring(0, deletionStart) + this.text.substring(deletionEnd);

		for (existingAttribute in attributes) {
			var start = existingAttribute.position;
			var end = existingAttribute.position + existingAttribute.length;

			if (existingAttribute == attributeToDelete)
				continue;

			var editedAttribute = existingAttribute;

			if (start <= deletionStart) {
				if (end <= deletionStart) {} else if (end <= deletionEnd) {
					editedAttribute.length = deletionStart - start;

					if (existingAttribute.length > 0 && editedAttribute.length <= 0)
						continue;
				} else {
					editedAttribute.length -= attributeToDelete.length;
				}
			} else if (start >= deletionEnd) {
				editedAttribute.position = start - attributeToDelete.length;
			} else if (start >= deletionStart && end <= deletionEnd) {
				continue;
			} else if (start >= deletionStart && end > deletionEnd) {
				var overlapLength = deletionEnd - start;
				var newStart = deletionStart;
				var newLength = existingAttribute.length - overlapLength;

				editedAttribute.position = newStart;
				editedAttribute.length = newLength;
			}

			newAttributes.push(editedAttribute);
		}

		return new MarkupParseResult(editedSubString, newAttributes);
	}
}
