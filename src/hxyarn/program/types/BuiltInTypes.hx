package hxyarn.program.types;

class BuiltInTypes {
	public static final undefined:IType = null;
	public static var string:IType = new StringType();
	public static var number:IType = new NumberType();
	public static var boolean:IType = new BooleanType();
	public static var any:IType = new AnyType();

	public static var all:Array<IType> = [string, number, boolean, any];

	public static function getType(o:Dynamic):IType {
		if (o == null)
			return BuiltInTypes.undefined;

		if (Std.isOfType(o, String))
			return BuiltInTypes.string;

		if (Std.isOfType(o, Int))
			return BuiltInTypes.number;

		if (Std.isOfType(o, Float))
			return BuiltInTypes.number;

		if (Std.isOfType(o, Bool))
			return BuiltInTypes.boolean;

		return BuiltInTypes.any;
	}
}
