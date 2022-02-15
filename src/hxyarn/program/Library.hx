package src.hxyarn.program;

import haxe.Exception;

typedef ReturingFunction = Array<Value>->Dynamic;
typedef Function = Array<Value>->Void;

class Library {
	var functions = new Map<String, FunctionInfo>();

	public function new() {}

	public function getFunction(name:String):FunctionInfo {
		if (functions.exists(name)) {
			return functions.get(name);
		}

		throw new Exception('$name is not a valid function');
	}

	public function importLibrary(otherLibrary:Library) {
		for (name => func in otherLibrary.functions) {
			functions.set(name, func);
		}
	}

	function registerFunctionInfo(func:FunctionInfo) {
		functions.set(func.name, func);
	}

	public function registerFunction(name:String, parameterCount:Int, implementation:Function) {
		var info = new FunctionInfo(name, parameterCount).forFunction(implementation);
		registerFunctionInfo(info);
	}

	public function registerReturningFunction(name:String, parameterCount:Int, implementation:ReturingFunction) {
		var info = new FunctionInfo(name, parameterCount).forReturningFunction(implementation);
		registerFunctionInfo(info);
	}

	public function functionExists(name:String):Bool {
		return functions.exists(name);
	}

	public function deregisterFunction(name:String) {
		if (functions.exists(name))
			functions.remove(name);
	}
}

class FunctionInfo {
	public function new(name:String, paramCount:Int) {
		this.name = name;
		this.paramCount = paramCount;
	}

	public function forFunction(f:Function):FunctionInfo {
		this.noreturnFunction = f;
		this.returningFuncation = null;
		return this;
	}

	public function forReturningFunction(f:ReturingFunction):FunctionInfo {
		this.noreturnFunction = null;
		this.returningFuncation = f;
		return this;
	}

	public var name(default, set):String;

	function set_name(newName) {
		return name = newName;
	}

	public var paramCount(default, set):Int;

	function set_paramCount(newParamCount) {
		return paramCount = newParamCount;
	}

	var noreturnFunction:Function;
	var returningFuncation:ReturingFunction;

	public function returnsValue():Bool {
		return returningFuncation != null;
	}

	public function invoke(parameters:Array<Value>):Value {
		return invokeWithArray(parameters);
	}

	public function invokeWithArray(parameters:Array<Value>):Value {
		var numberOfParameters = parameters != null ? parameters.length : 0;

		if (paramCount == numberOfParameters || paramCount == -1) {
			if (returnsValue()) {
				return new Value(returningFuncation(parameters));
			} else {
				noreturnFunction(parameters);
				return Value.NULL;
			}
		} else {
			var error = 'Incorrect number of parameters for function $name (expected $paramCount, got ${parameters.length})';

			throw new Exception(error);
		}
	}
}
