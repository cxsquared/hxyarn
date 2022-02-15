package src.hxyarn.program.types;

import haxe.Constraints.Function;

typedef MethodCollection = Map<String, Function>;

interface IType {
	public var name:String;
	public var parent:IType;
	public var description(get, null):String;
	public var methods:MethodCollection;
}
