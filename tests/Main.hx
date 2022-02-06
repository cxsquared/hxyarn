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
		// runTest('./yarns/Basic.yarn', './yarns/testcases/Basic.testplan');
		// runTest('./yarns/Options.yarn', './yarns/testcases/Options.testplan');
		// runTest('./yarns/Expressions.yarn', './yarns/testcases/Expressions.testplan');
		runTest('./yarns/Commands.yarn', './yarns/testcases/Commands.testplan');
		// runTest('./yarns/FormatFunctions.yarn', './yarns/testcases/FormatFunctions.testplan');
		// runFunctionTest('./yarns/Functions.yarn', './yarns/testcases/Functions.testplan');
		// runTest('./yarns/IfStatements.yarn', './yarns/testcases/IfStatements.testplan');
		// runTest('./yarns/InlineExpressions.yarn', './yarns/testcases/InlineExpressions.testplan');
		// runTest('./yarns/Lines.yarn', './yarns/testcases/Lines.testplan');
		// runTest('./yarns/NodeHeaders.yarn', './yarns/testcases/NodeHeaders.testplan');
		// runTest('./yarns/ShortcutOptions.yarn', './yarns/testcases/ShortcutOptions.testplan');
		// runTest('./yarns/Smileys.yarn', './yarns/testcases/Smileys.testplan');
		// runTest('./yarns/Types.yarn', './yarns/testcases/Types.testplan');
		// runTest('./yarns/VariableStorage.yarn', './yarns/testcases/VariableStorage.testplan');
	}

	static function runJson() {
		runTest('./yarns/Basic.json', './yarns/testcases/Basic.testplan');
		runTest('./yarns/Commands.json', './yarns/testcases/Commands.testplan');
		runTest('./yarns/Expressions.json', './yarns/testcases/Expressions.testplan');
		runTest('./yarns/FormatFunctions.json', './yarns/testcases/FormatFunctions.testplan');
		runFunctionTest('./yarns/Functions.json', './yarns/testcases/Functions.testplan');
		runTest('./yarns/IfStatements.json', './yarns/testcases/IfStatements.testplan');
		runTest('./yarns/InlineExpressions.json', './yarns/testcases/InlineExpressions.testplan');
		runTest('./yarns/Lines.json', './yarns/testcases/Lines.testplan');
		runTest('./yarns/NodeHeaders.json', './yarns/testcases/NodeHeaders.testplan');
		runTest('./yarns/ShortcutOptions.json', './yarns/testcases/ShortcutOptions.testplan');
		runTest('./yarns/Smileys.json', './yarns/testcases/Smileys.testplan');
		runTest('./yarns/Types.json', './yarns/testcases/Types.testplan');
		runTest('./yarns/VariableStorage.json', './yarns/testcases/VariableStorage.testplan');
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
