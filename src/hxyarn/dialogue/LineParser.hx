package hxyarn.dialogue;

import hxyarn.compiler.YarnStringTools;
import haxe.iterators.StringIteratorUnicode;
import hxyarn.dialogue.markup.NoMarkupTextProcessor;
import hxyarn.dialogue.markup.MarkupProperty;
import hxyarn.dialogue.markup.MarkupValue;
import hxyarn.dialogue.markup.MarkupValue.MarkupValueType;
import hxyarn.dialogue.markup.MarkupAttributeMarker;
import hxyarn.dialogue.markup.MarkupAttribute;
import hxyarn.dialogue.markup.MarkupParseResult;

using hxyarn.dialogue.markup.IAttributeMarkerProcessor;

class LineParser {
	public static final ReplacementMarkerContents = "contents";
	public static final CharacterAttribute = "character";
	public static final CharacterAttributeNameProperty = "name";
	public static final TrimWhitespaceProperty = "trimwhitespace";

	public static final EndOfCharacterMarker = new EReg(':\\s*', "i");

	final markerProcessors = new Map<String, IAttributeMarkerProcessor>();

	var input:String = "";
	var current:Int = 0;
	var offset:Int = 0;

	var position:Int = 0;

	var sourcePosition:Int = 0;

	public function new() {
		this.registerMarkerProcessor("nomarkup", new NoMarkupTextProcessor());
	}

	public function registerMarkerProcessor(name:String, processor:IAttributeMarkerProcessor) {
		if (markerProcessors.exists(name)) {
			throw 'Marker processor already registered: $name';
		}

		this.markerProcessors.set(name, processor);
	}

	public function parseMarkup(input:String):MarkupParseResult {
		if (input == null && input == "") {
			return new MarkupParseResult("", new Array<MarkupAttribute>());
		}

		// todo normlize
		this.input = input;

		var lenght = input.length;
		var sb = new StringBuf();

		var markers = new List<MarkupAttributeMarker>();

		var nextCharacter = new UnicodeString(input).charAt(0);
		var lastCharacter = "\\0";

		while (current < lenght && nextCharacter != null) {
			var c = nextCharacter;

			if (c == "\\") {
				var nextC = peek();

				if (nextC == "[" || nextC == "]") {
					c = advance();
					sb.add(c);
					this.sourcePosition += 1;
					nextCharacter = advance();
					continue;
				}
			}

			if (c == "[") {
				this.position = sb.length;

				var marker = this.parseAttributeMarker();

				markers.add(marker);

				var hadPrecedingWhitespace = this.position == 0 || StringTools.isSpace(lastCharacter, 0);
				var wasReplacementMarker = false;

				if (marker.name != null && this.markerProcessors.exists(marker.name)) {
					wasReplacementMarker = true;
					var replacementText = this.processReplacementMarker(marker);

					sb.add(replacementText);
				}

				var trimWhitespaceIfAble = false;

				if (hadPrecedingWhitespace) {
					if (marker.type == TagType.SELFCLOSING) {
						trimWhitespaceIfAble = !wasReplacementMarker;
					}

					var prop = marker.tryGetProperty(TrimWhitespaceProperty);
					if (prop != null) {
						if (prop.type != MarkupValueType.BOOL) {
							throw 'Error parsing line $input: attribute ${marker.name} at position $position has a ${prop.type.getName().toLowerCase()} property \"$TrimWhitespaceProperty\" - this property is required to be a boolean value.';
						}

						trimWhitespaceIfAble = prop.boolValue;
					}
				}

				if (trimWhitespaceIfAble) {
					if (StringTools.isSpace(peek(), 0)) {
						advance();
						this.sourcePosition += 1;
					}
				}
			} else {
				sb.add(c);
				this.sourcePosition += 1;
			}

			lastCharacter = c;
			nextCharacter = advance();
		}

		var attributes = this.buildAttributesFromMarkers(markers);

		var characterAttributesInPresent = false;
		for (attribute in attributes) {
			if (attribute.name == CharacterAttribute) {
				characterAttributesInPresent = true;
			}
		}

		if (characterAttributesInPresent == false) {
			if (EndOfCharacterMarker.match(this.input)) {
				var matchPos = EndOfCharacterMarker.matchedPos();
				var endRange = matchPos.pos + matchPos.len;
				var characterName = this.input.substr(0, matchPos.pos);

				var nameValue = new MarkupValue();
				nameValue.type = MarkupValueType.STRING;
				nameValue.stringValue = characterName;

				var nameProperty = new MarkupProperty(CharacterAttributeNameProperty, nameValue);

				var characterAttribute = new MarkupAttribute(0, 0, endRange, CharacterAttribute, [nameProperty]);

				attributes.push(characterAttribute);
			}
		}

		offset = 0;
		position = 0;
		current = 0;
		return new MarkupParseResult(sb.toString(), attributes);
	}

	function processReplacementMarker(marker:MarkupAttributeMarker):String {
		if (marker.type != TagType.OPEN && marker.type != TagType.SELFCLOSING)
			return "";

		if (marker.type == TagType.OPEN) {
			var markerContents = parseRawTextUpToAttributeClose(marker.name);

			var mkValue = new MarkupValue();
			mkValue.type = MarkupValueType.STRING;
			mkValue.stringValue = markerContents;
			marker.properties.push(new MarkupProperty(ReplacementMarkerContents, mkValue));
		}

		var replacementText = this.markerProcessors.get(marker.name).replacementTextForMarker(marker);

		return replacementText;
	}

	function parseRawTextUpToAttributeClose(name:String):String {
		var reminderOfLine = readToEnd();

		var regex = new EReg('\\[\\s*\\/\\s*($name)?\\s*\\]', "i");
		if (regex.match(reminderOfLine) == false)
			throw 'Unterminated marker $name in line $input';

		var matchPos = regex.matchedPos();
		var claseMarkerPosition = matchPos.pos;

		var rawTextSubstring = reminderOfLine.substr(0, claseMarkerPosition);
		var lineAfterRawText = reminderOfLine.substr(claseMarkerPosition);

		this.offset = current;
		this.current = 0;

		return rawTextSubstring;
	}

	function readToEnd():String {
		var remainderOfLine = this.input.substr(this.current);
		current = input.length;
		return remainderOfLine;
	}

	function buildAttributesFromMarkers(markers:List<MarkupAttributeMarker>):Array<MarkupAttribute> {
		var unclosedMarkerList = new List<MarkupAttributeMarker>();

		var attributes = new Array<MarkupAttribute>();

		for (marker in markers) {
			switch (marker.type) {
				case TagType.OPEN:
					unclosedMarkerList.push(marker);
				case TagType.CLOSE:
					var matchedOpenMarker:MarkupAttributeMarker = null;
					for (openmarker in unclosedMarkerList) {
						if (openmarker.name == marker.name) {
							matchedOpenMarker = openmarker;
							break;
						}
					}

					if (matchedOpenMarker == null)
						throw 'Unexpected close marker ${marker.name}';

					unclosedMarkerList.remove(matchedOpenMarker);

					var lenght = marker.position - matchedOpenMarker.position;
					var attribute = MarkupAttribute.createFromMarker(matchedOpenMarker, lenght);

					attributes.push(attribute);
				case TagType.SELFCLOSING:
					var attribute = MarkupAttribute.createFromMarker(marker, 0);
					attributes.push(attribute);
				case TagType.CLOSEALL:
					for (openMarker in unclosedMarkerList) {
						var length = marker.position - openMarker.position;
						var attribute = MarkupAttribute.createFromMarker(openMarker, length);

						attributes.push(attribute);
					}

					unclosedMarkerList.clear();
			}
		}

		attributes.sort(function(a, b) {
			if (a.sourcePosition == b.sourcePosition)
				return 0;
			else if (a.sourcePosition < b.sourcePosition)
				return -1;
			else
				return 1;
		});

		return attributes;
	}

	function advance():String {
		if (offset + current + 1 >= input.length)
			return null;

		current++;
		return String.fromCharCode(new UnicodeString(input).charCodeAt(offset + current));
	}

	function peek():String {
		if (offset + current + 1 >= input.length) {
			return null;
		}

		return input.substr(offset + current + 1, 1);
	}

	function parseAttributeMarker():MarkupAttributeMarker {
		var sourcePositionAtMarkerStart = this.sourcePosition;

		this.sourcePosition += 1;

		if (peek() == "/") {
			this.parseCharacter("/");

			if (peek() == ']') {
				this.parseCharacter("]");
				return new MarkupAttributeMarker(null, this.position, sourcePositionAtMarkerStart, new Array<MarkupProperty>(), TagType.CLOSEALL);
			} else {
				var tagName = this.parseId();
				this.parseCharacter(']');
				return new MarkupAttributeMarker(tagName, this.position, sourcePositionAtMarkerStart, new Array<MarkupProperty>(), TagType.CLOSE);
			}
		}

		var attributeName = this.parseId();

		var properties = new Array<MarkupProperty>();

		if (peek() == "=") {
			this.parseCharacter("=");
			var value = this.parseValue();
			properties.push(new MarkupProperty(attributeName, value));
		}

		while (true) {
			this.consumeWhiteSpace();
			var next = peek();
			this.assertNotEndOfInput(next);

			if (next == "]") {
				this.parseCharacter("]");
				return new MarkupAttributeMarker(attributeName, this.position, sourcePositionAtMarkerStart, properties, TagType.OPEN);
			}

			if (next == "/") {
				this.parseCharacter("/");
				this.parseCharacter("]");
				return new MarkupAttributeMarker(attributeName, this.position, sourcePositionAtMarkerStart, properties, TagType.SELFCLOSING);
			}

			var propertyName = this.parseId();
			this.parseCharacter('=');
			var propertyValue = this.parseValue();

			properties.push(new MarkupProperty(propertyName, propertyValue));
		}
	}

	function parseValue():MarkupValue {
		if (this.peekNumeric()) {
			var int = this.parseInteger();

			if (peek() == '.') {
				this.parseCharacter('.');

				var fraction = this.parseInteger();

				var fractionDigits = Std.string(fraction).length;
				var floatValue = int + cast(fraction / Math.pow(10, fractionDigits), Float);

				var mkValue = new MarkupValue();
				mkValue.floatValue = floatValue;
				mkValue.type = MarkupValueType.FLOAT;
				return mkValue;
			} else {
				var mkValue = new MarkupValue();
				mkValue.integerValue = int;
				mkValue.type = MarkupValueType.INTEGER;
				return mkValue;
			}
		}

		if (peek() == '"') {
			var mkValue = new MarkupValue();
			mkValue.stringValue = this.parseString();
			mkValue.type = MarkupValueType.STRING;
			return mkValue;
		}

		var word = parseId();

		if (word == "true") {
			var mkValue = new MarkupValue();
			mkValue.boolValue = true;
			mkValue.type = MarkupValueType.BOOL;
			return mkValue;
		} else if (word == "false") {
			var mkValue = new MarkupValue();
			mkValue.boolValue = false;
			mkValue.type = MarkupValueType.BOOL;
			return mkValue;
		} else {
			var mkValue = new MarkupValue();
			mkValue.stringValue = word;
			mkValue.type = MarkupValueType.STRING;
			return mkValue;
		}
	}

	function peekWhitespace() {
		this.consumeWhiteSpace();
		var next = peek();
		if (next == null)
			return false;

		return StringTools.isSpace(next, 0);
	}

	function peekNumeric():Bool {
		this.consumeWhiteSpace();
		var next = peek();
		if (next == null)
			return false;

		return isDigit(next);
	}

	function parseInteger() {
		this.consumeWhiteSpace();

		var intsb = new StringBuf();

		while (true) {
			var tempNext = peek();
			assertNotEndOfInput(tempNext);
			var nextChar = tempNext;

			if (isDigit(nextChar)) {
				advance();
				intsb.add(nextChar);
				sourcePosition += 1;
			} else {
				return Std.parseInt(intsb.toString());
			}
		}
	}

	function parseId() {
		this.consumeWhiteSpace();
		var idsb = new StringBuf();

		var tempNext = advance();
		sourcePosition += 1;
		assertNotEndOfInput(tempNext);
		var nextChar = tempNext;

		// TODO: isSurrogate?
		if (isAlpha(nextChar) || nextChar == '_') {
			idsb.add(nextChar);
		} else {
			throw 'Error parsing line $input: expected an identifier at position $position, but found \"$nextChar\"';
		}

		while (true) {
			tempNext = peek();
			if (tempNext == null)
				break;

			nextChar = tempNext;

			// TODO: isSurrogate?
			if (isAlphaNumeric(nextChar) || nextChar == '_') {
				idsb.add(nextChar);
				advance();
				this.sourcePosition += 1;
			} else {
				break;
			}
		}

		return idsb.toString();
	}

	function isDigit(c:String):Bool {
		return c >= '0' && c <= '9';
	}

	var alpha = ~/^[a-zA-Z_$]+$/;

	function isAlpha(c:String):Bool {
		return alpha.match(c);
	}

	function isAlphaNumeric(c:String):Bool {
		return isAlpha(c) || isDigit(c);
	}

	function parseString():String {
		this.consumeWhiteSpace();

		var sb = new StringBuf();

		var tempNext = advance();
		this.assertNotEndOfInput(tempNext);
		this.sourcePosition += 1;

		var nextchar = tempNext;
		if (nextchar != '"') {
			throw 'Error parsing line $input: expected \" at position $position, but found $nextchar';
		}

		while (true) {
			tempNext = advance();
			this.assertNotEndOfInput(tempNext);
			this.sourcePosition += 1;
			nextchar = tempNext;

			if (nextchar == '"') {
				break;
			} else if (nextchar == "\\") {
				var newNext = advance();
				this.assertNotEndOfInput(newNext);
				this.sourcePosition += 1;
				var newNextChar = newNext;
				if (newNextChar == "\\" || newNextChar == '"') {
					sb.add(newNextChar);
				}
			} else {
				sb.add(nextchar);
			}
		}

		return sb.toString();
	}

	function parseCharacter(c:String) {
		this.consumeWhiteSpace();

		var tempNext = advance();
		assertNotEndOfInput(tempNext);
		if (tempNext != c) {
			throw 'Error parsing line $input: expected character \"$c\" at position $position, but found \"$tempNext\"';
		}

		this.sourcePosition += 1;
	}

	function assertNotEndOfInput(c:String) {
		if (c == null) {
			throw 'Error parsing line $input: unexpected end of input at position $position.';
		}
	}

	function consumeWhiteSpace(?allowEndOfLine:Bool = false) {
		while (true) {
			var tempNext = peek();
			if (tempNext == null && allowEndOfLine == false) {
				throw 'Error parsing line $input: unexpected end of input at position $position.';
			}

			if (StringTools.isSpace(tempNext, 0)) {
				advance();
				this.sourcePosition += 1;
			} else {
				return;
			}
		}
	}
}
