package tests;

import tests.TestBase;
import tests.FunctionTest;
import tests.ShipTest;

class Main {
	public static function main() {
		// Basic
		// new TestBase('./yarns/Basic.json', './yarns/testcases/Basic.testplan').start();
		// Commands
		// new TestBase('./yarns/Commands.json', './yarns/testcases/Commands.testplan').start();
		// Expression
		// new TestBase('./yarns/Expressions.json', './yarns/testcases/Expressions.testplan').start();
		// FormatFunctions FAILING
		// new TestBase('./yarns/FormatFunctions.json', './yarns/testcases/FormatFunctions.testplan').start();
		// Function
		new FunctionTest().start();
		// IfStatements
		new TestBase('./yarns/IfStatements.json', './yarns/testcases/IfStatements.testplan').start();
		// InlineExpressions FAILING
		new TestBase('./yarns/InlineExpressions.json', './yarns/testcases/InlineExpressions.testplan').start();
		// Lines FAILING
		// new TestBase('./yarns/Lines.json', './yarns/testcases/Lines.testplan').start();
		// NodeHeaders
		new TestBase('./yarns/NodeHeaders.json', './yarns/testcases/NodeHeaders.testplan').start();
		// ShortcutOptions FAILING
		// new TestBase('./yarns/ShortcutOptions.json', './yarns/testcases/ShortcutOptions.testplan').start();
		// Smileys FAILING
		// new TestBase('./yarns/Smileys.json', './yarns/testcases/Smileys.testplan').start();
		// Types
		new TestBase('./yarns/Types.json', './yarns/testcases/Types.testplan').start();
		// VariableStorage
		new TestBase('./yarns/VariableStorage.json', './yarns/testcases/VariableStorage.testplan').start();
		// Ship
		new ShipTest().start();
	}
}
