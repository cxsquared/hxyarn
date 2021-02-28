package src.hxyarn.dialogue;

// https://www.unicode.org/cldr/cldr-aux/charts/36.1/supplemental/language_plural_rules.html
// TODO: Pull this out into it's own library
class CLDR {
	public static function getOrdinalPluralCase(locale:String, value:Float):PluralCase {
		if (locale.toLowerCase() == "en") {
			return getEnOrdinalPluralCase(value);
		}

		return PluralCase.One;
	}

	public static function getCardinalPluralCase(locale:String, value:Float):PluralCase {
		if (locale.toLowerCase() == "en") {
			return getEnCardinalPluralCase(value);
		}

		return PluralCase.One;
	}

	static function getEnOrdinalPluralCase(number:Float):PluralCase {
		var n = Math.abs(number);

		if ((((n % 10) == 1) && !(((n % 100) == 11)))) {
			return PluralCase.One;
		}

		if ((((n % 10) == 2) && !(((n % 100) == 12)))) {
			return PluralCase.Two;
		}

		if ((((n % 10) == 3) && !(((n % 100) == 13)))) {
			return PluralCase.Few;
		}

		return PluralCase.Other;
	}

	static function getEnCardinalPluralCase(number:Float):PluralCase {
		var i = Math.floor(number);
		var v = visibleFractionalDigits(number, true);

		if (((i == 1) && (v == 0))) {
			return PluralCase.One;
		}

		return PluralCase.Other;
	}

	static function visibleFractionalDigits(number:Float, trailingZeroes:Bool):Int {
		var text = Std.string(number);
		var text2 = text.indexOf('.') < 0 ? "" : text.split('.')[1];
		// TODO implement trailing zeros
		return text2.length;
	}
}

enum PluralCase {
	One;
	Two;
	Few;
	Many;
	Other;
}
