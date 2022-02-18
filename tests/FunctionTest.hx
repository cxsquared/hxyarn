package tests;

import hxyarn.program.types.BuiltInTypes;
import hxyarn.program.Value;
import tests.TestBase;

class FunctionTest extends TestBase {
	public function new(yarnFile:String, testPlan:String) {
		super(yarnFile, testPlan);

		dialogue.library.registerFunction("add_three_operands", 3, function(arguments:Array<Value>) {
			return arguments[0].asNumber() + arguments[1].asNumber() + arguments[2].asNumber();
		}, BuiltInTypes.number);

		dialogue.library.registerFunction("last_value", 0, function(arguments:Array<Value>) {
			return arguments[arguments.length - 1];
		}, BuiltInTypes.number);
	}
}
