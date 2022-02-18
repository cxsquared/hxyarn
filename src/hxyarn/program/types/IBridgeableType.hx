package hxyarn.program.types;

interface IBridgeableType<T> extends IType {
	public var defaultValue:T;
	function toBridgedType(value:Value):T;
}
