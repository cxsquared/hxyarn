package src.hxyarn.program.types;

class TypeUtils {
	public static function findImplementingTypeForMethod(type:IType, methodName:String):IType {
		if (type == null)
			throw "Argument exception: type cannot be null";

		if (methodName == null || StringTools.trim(methodName) == "")
			throw "Argument exception: methodName cannot be null or empty";

		var currentType = type;

		while (currentType != null) {
			if (currentType.methods != null && currentType.methods.exists(methodName)) {
				return currentType;
			}

			currentType = currentType.parent;
		}

		return null;
	}

	public static function isSubtype(parentType:IType, subType:IType) {
		if (subType == BuiltInTypes.undefined && parentType == BuiltInTypes.undefined)
			return true;

		if (subType == BuiltInTypes.undefined)
			return false;

		var currentType = subType;

		while (currentType != null) {
			if (currentType == parentType)
				return true;

			currentType = currentType.parent;
		}

		return false;
	}

	public static function getCanonicalNameforMethod(implementingType:IType, methodName:String):String {
		if (implementingType == null)
			throw "Argument exception: implementingType cannot be null";

		if (methodName == null || StringTools.trim(methodName) == "")
			throw "Argument exception: methodName cannot be null or empty";

		return '${implementingType.name}.${methodName}';
	}
}
