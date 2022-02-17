package src.hxyarn.program.types;

import src.hxyarn.program.Library.ValueFunction;

typedef Method = {
	func:ValueFunction,
	numberOfArgs:Int,
	returnType:IType
};

typedef MethodCollection = Map<String, Method>;

interface IType {
	public var name:String;
	public var description(get, null):String;
	public var methods:MethodCollection;
	public function defaultMethods():MethodCollection;
	public function parent():IType;
}
