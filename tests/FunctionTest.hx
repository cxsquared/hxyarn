package tests;

import src.hxyarn.Value;
import src.hxyarn.compiler.Compiler;
import tests.TestBase;

class FunctionTest extends TestBase {
	public function new() {
		super();

		var compiler = Compiler.compileFile('./yarns/Functions.json');
		stringTable = compiler.stringTable;

		dialogue.library.registerReturningFunction("add_three_operands", 3, function(arguments:Array<Value>) {
			return arguments[0].asNumber() + arguments[1].asNumber() + arguments[2].asNumber();
		});

		dialogue.library.registerReturningFunction("last_value", -1, function(arguments:Array<Value>) {
			return arguments[arguments.length - 1];
		});

		dialogue.addProgram(compiler.program);
		dialogue.setNode("Start");
		dialogue.resume();
	}
}
