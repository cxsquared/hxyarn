package tests;

import haxe.Exception;
import tests.TestBase;
import tests.FunctionTest;

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
		runTest('./yarns/yarn/Expressions.yarn', './yarns/testcases/Expressions.testplan');
		// Passing
		// runTest('./yarns/yarn/Options.yarn', './yarns/testcases/Options.testplan');
		// Passing
		// runFunctionTest('./yarns/yarn/Functions.yarn', './yarns/testcases/Functions.testplan');
		// Pasing
		// runTest('./yarns/yarn/Lines.yarn', './yarns/testcases/Lines.testplan');
		// Pasing
		// runTest('./yarns/yarn/IfStatements.yarn', './yarns/testcases/IfStatements.testplan');
		// Passing
		// runTest('./yarns/yarn/VariableStorage.yarn', './yarns/testcases/VariableStorage.testplan');
		// Passing
		// runTest('./yarns/yarn/NodeHeaders.yarn', './yarns/testcases/NodeHeaders.testplan');
		// Passing
		// runTest('./yarns/yarn/FormatFunctions.yarn', './yarns/testcases/FormatFunctions.testplan');
		// Passing
		// runTest('./yarns/yarn/InlineExpressions.yarn', './yarns/testcases/InlineExpressions.testplan');
		// Passing
		// runTest('./yarns/yarn/ShortcutOptions.yarn', './yarns/testcases/ShortcutOptions.testplan');
		// Passing
		// runTest('./yarns/yarn/Types.yarn', './yarns/testcases/Types.testplan');
		// Passing
		// runTest('./yarns/yarn/DecimalNumbers.yarn', './yarns/testcases/DecimalNumbers.testplan');
		// Passed
		// runTest('./yarns/yarn/Escaping.yarn', './yarns/testcases/Escaping.testplan');
		// Passing
		// runTest('./yarns/yarn/Smileys.yarn', './yarns/testcases/Smileys.testplan');
		// Failing
		// runTest('./yarns/yarn/Identifiers.yarn', './yarns/testcases/Identifiers.testplan');
		// Failing
		// runTest('./yarns/yarn/Jumps.yarn', './yarns/testcases/Jumps.testplan');
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
