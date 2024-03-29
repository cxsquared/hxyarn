package tests;

import haxe.Log;
import haxe.Exception;
import tests.TestBase;
import tests.FunctionTest;

class Main {
	public static function main() {
		runYarn();
	}

	static function runYarn() {
		// Failing
		runTest('./yarns/yarn/Identifiers.yarn', './yarns/testcases/Identifiers.testplan');
		// Passing
		runTest('./yarns/yarn/AnalysisTest.yarn', null);
		// Passing
		runTest('./yarns/yarn/Basic.yarn', './yarns/testcases/Basic.testplan');
		// Passing
		runTest('./yarns/yarn/Commands.yarn', './yarns/testcases/Commands.testplan');
		// Passing
		runTest('./yarns/yarn/Compiler.yarn', './yarns/testcases/Compiler.testplan');
		// Passing
		runTest('./yarns/yarn/DecimalNumbers.yarn', './yarns/testcases/DecimalNumbers.testplan');
		// Should Fail but doesn't right now
		runTest('./yarns/yarn/DuplicateLineTags.yarn', null);
		// Passing
		runTest('./yarns/yarn/Escaping.yarn', './yarns/testcases/Escaping.testplan');
		// Passing
		runTest('./yarns/yarn/Example.yarn', './yarns/testcases/Example.testplan');
		// Passing
		runTest('./yarns/yarn/Expressions.yarn', './yarns/testcases/Expressions.testplan');
		// Passing
		runTest('./yarns/yarn/FormatFunctions.yarn', './yarns/testcases/FormatFunctions.testplan');
		// Passing
		runFunctionTest('./yarns/yarn/Functions.yarn', './yarns/testcases/Functions.testplan');
		// Pasing
		runTest('./yarns/yarn/IfStatements.yarn', './yarns/testcases/IfStatements.testplan');
		// Passing
		runTest('./yarns/yarn/InlineExpressions.yarn', './yarns/testcases/InlineExpressions.testplan');
		// Passing
		runTest('./yarns/yarn/Jumps.yarn', './yarns/testcases/Jumps.testplan');
		// Pasing
		runTest('./yarns/yarn/Lines.yarn', './yarns/testcases/Lines.testplan');
		// Passing
		runTest('./yarns/yarn/NodeHeaders.yarn', './yarns/testcases/NodeHeaders.testplan');
		// Passing
		runTest('./yarns/yarn/Options.yarn', './yarns/testcases/Options.testplan');
		// Passing
		runTest('./yarns/yarn/ShortcutOptions.yarn', './yarns/testcases/ShortcutOptions.testplan');
		// Passing
		runTest('./yarns/yarn/Smileys.yarn', './yarns/testcases/Smileys.testplan');
		// Passing
		runTest('./yarns/yarn/Types.yarn', './yarns/testcases/Types.testplan');
		// Passing
		runTest('./yarns/yarn/VariableStorage.yarn', './yarns/testcases/VariableStorage.testplan');
		// Passing
		runTest('./yarns/yarn/VisitCount.yarn', './yarns/testcases/VisitCount.testplan');
		// Passing
		runTest('./yarns/yarn/VisitTracking.yarn', './yarns/testcases/VisitTracking.testplan');
	}

	static function runTest(file:String, testPlan:String) {
		try {
			var test = new TestBase(file, testPlan);
			test.start();
		} catch (e:Exception) {
			Log.trace('------$file: $testPlan failed----------');
			Log.trace(e.message);
			Log.trace(e.stack);
		}
	}

	static function runFunctionTest(file:String, testPlan:String) {
		try {
			var test = new FunctionTest(file, testPlan);
			test.start();
		} catch (e:Exception) {
			Log.trace('------$file: $testPlan failed----------');
			Log.trace(e.message);
			Log.trace(e.stack);
		}
	}
}
