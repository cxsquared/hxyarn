package src.hxyarn.compiler;

import src.hxyarn.program.types.IType;

class Declaration {
	public var name:String;
	public var defaultValue:Dynamic;
	public var description:String;
	public var sourceFileName:String;
	public var sourceNodeName:String;
	public var sourceFileLine:Int;
	public var sourceNodeLine:Int;
	public var isImplicit:Bool;
	public var type:IType;

	public static function createVariable(name:String, type:IType, defaultValue:Dynamic, description:String = null):Declaration {
		if (type == null)
			throw "type cannot be null";
		if (name == null || name == "")
			throw "name cannot be null or empty";
		if (defaultValue == null)
			throw "defaultValue cannot be null";

		var decl = new Declaration();
		decl.name = name;
		decl.type = type;
		decl.defaultValue = defaultValue;
		decl.description = description;

		return decl;
	}

	public function new() {}
}
