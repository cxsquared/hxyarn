package tests;

import src.hxyarn.compiler.Compiler;
import tests.TestBase;

class ExpressionTest extends TestBase {
	public function new() {
		super();

		var compiler = Compiler.compileFile('./yarns/Expressions.json');
		stringTable = compiler.stringTable;

		dialogue.addProgram(compiler.program);
		dialogue.setNode("Start");
		dialogue.resume();
	}
}
