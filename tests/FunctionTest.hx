package tests;

import src.hxyarn.Value;
import tests.TestBase;

class FunctionTest extends TestBase {
	public function new(yarnFile:String, testPlan:String) {
		super(yarnFile, testPlan);

		dialogue.library.registerReturningFunction("add_three_operands", 3, function(arguments:Array<Value>) {
			return arguments[0].asNumber() + arguments[1].asNumber() + arguments[2].asNumber();
		});

		dialogue.library.registerReturningFunction("last_value", -1, function(arguments:Array<Value>) {
			return arguments[arguments.length - 1];
		});
	}
}
