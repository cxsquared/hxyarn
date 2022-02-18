package hxyarn.program;

import hxyarn.program.types.TypeUtils;
import hxyarn.program.types.IType;
import hxyarn.program.types.BuiltInTypes;
import haxe.Exception;

typedef ValueFunction = Array<Value>->Dynamic;

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

	public function registerFunction(name:String, parameterCount:Int, implementation:ValueFunction, ?returnType:IType = null) {
		var info = new FunctionInfo(name, parameterCount, implementation, returnType);
		registerFunctionInfo(info);
	}

	public function functionExists(name:String):Bool {
		return functions.exists(name);
	}

	public function deregisterFunction(name:String) {
		if (functions.exists(name))
			functions.remove(name);
	}

	public function registerMethods(type:IType) {
		var methods = type.defaultMethods();

		if (methods == null)
			return;

		for (methodName => methodInfo in methods) {
			var methodName = methodName;

			var canonicalName = TypeUtils.getCanonicalNameforMethod(type, methodName);

			this.registerFunction(canonicalName, methodInfo.numberOfArgs, methodInfo.func, methodInfo.returnType);
		}
	}
}

class FunctionInfo {
	public var name:String;

	var func:ValueFunction;

	public var paramCount:Int;

	var returnType:IType;

	public function new(name:String, paramCount:Int, func:ValueFunction, ?returnType:IType = null) {
		this.name = name;
		this.func = func;
		this.paramCount = paramCount;
		this.returnType = returnType;
	}

	public function returnsValue():Bool {
		return returnType != null;
	}

	public function invoke(parameters:Array<Value>):Value {
		return invokeWithArray(parameters);
	}

	public function invokeWithArray(parameters:Array<Value>):Value {
		var numberOfParameters = parameters != null ? parameters.length : 0;

		if (paramCount == numberOfParameters || paramCount == -1) {
			if (returnsValue()) {
				return new Value(func(parameters), this.returnType); // TODO fix return type
			} else {
				func(parameters);
				return Value.NULL;
			}
		} else {
			var error = 'Incorrect number of parameters for function $name (expected $paramCount, got ${parameters.length})';

			throw new Exception(error);
		}
	}
}
