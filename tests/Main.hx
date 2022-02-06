package tests;

import haxe.Exception;
import tests.TestBase;
import tests.FunctionTest;
import tests.ShipTest;

class Main {
	public static function main() {
		runYarn();
	}

	static function runYarn() {
		// Passing
		// runTest('./yarns/yarn/Basic.yarn', './yarns/testcases/Basic.testplan');
		// Passing
		// runTest('./yarns/yarn/Commands.yarn', './yarns/testcases/Commands.testplan');
		// Passing
		// runTest('./yarns/yarn/Expressions.yarn', './yarns/testcases/Expressions.testplan');
		// Passing
		// runTest('./yarns/yarn/Options.yarn', './yarns/testcases/Options.testplan');
		// Failing
		// runTest('./yarns/yarn/FormatFunctions.yarn', './yarns/testcases/FormatFunctions.testplan');
		// Passing
		// runFunctionTest('./yarns/yarn/Functions.yarn', './yarns/testcases/Functions.testplan');
		// Failing
		// runTest('./yarns/yarn/IfStatements.yarn', './yarns/testcases/IfStatements.testplan');
		// Failing
		// runTest('./yarns/yarn/InlineExpressions.yarn', './yarns/testcases/InlineExpressions.testplan');
		// Failing
		// runTest('./yarns/yarn/Lines.yarn', './yarns/testcases/Lines.testplan');
		// Passing
		// runTest('./yarns/yarn/NodeHeaders.yarn', './yarns/testcases/NodeHeaders.testplan');
		// Failing
		// runTest('./yarns/yarn/ShortcutOptions.yarn', './yarns/testcases/ShortcutOptions.testplan');
		// Failing
		// runTest('./yarns/yarn/Smileys.yarn', './yarns/testcases/Smileys.testplan');
		// Failing
		// runTest('./yarns/yarn/Types.yarn', './yarns/testcases/Types.testplan');
		// Failing
		// runTest('./yarns/yarn/VariableStorage.yarn', './yarns/testcases/VariableStorage.testplan');
	}

	static function runJson() {
		runTest('./yarns/json/Basic.json', './yarns/testcases/Basic.testplan');
		runTest('./yarns/json/Commands.json', './yarns/testcases/Commands.testplan');
		runTest('./yarns/json/Expressions.json', './yarns/testcases/Expressions.testplan');
		runTest('./yarns/json/FormatFunctions.json', './yarns/testcases/FormatFunctions.testplan');
		runFunctionTest('./yarns/json/Functions.json', './yarns/testcases/Functions.testplan');
		runTest('./yarns/json/IfStatements.json', './yarns/testcases/IfStatements.testplan');
		runTest('./yarns/json/InlineExpressions.json', './yarns/testcases/InlineExpressions.testplan');
		runTest('./yarns/json/Lines.json', './yarns/testcases/Lines.testplan');
		runTest('./yarns/json/NodeHeaders.json', './yarns/testcases/NodeHeaders.testplan');
		runTest('./yarns/json/ShortcutOptions.json', './yarns/testcases/ShortcutOptions.testplan');
		runTest('./yarns/json/Smileys.json', './yarns/testcases/Smileys.testplan');
		runTest('./yarns/json/Types.json', './yarns/testcases/Types.testplan');
		runTest('./yarns/json/VariableStorage.json', './yarns/testcases/VariableStorage.testplan');
	}

	static function runTest(file:String, testPlan:String) {
		try {
			var test = new TestBase(file, testPlan);
			test.start();
		} catch (e:Exception) {
			trace('------$file: $testPlan failed----------');
			trace(e.message);
			trace(e.stack);
		}
	}

	static function runFunctionTest(file:String, testPlan:String) {
		try {
			var test = new FunctionTest(file, testPlan);
			test.start();
		} catch (e:Exception) {
			trace('------$file: $testPlan failed----------');
			trace(e.message);
			trace(e.stack);
		}
	}
}
