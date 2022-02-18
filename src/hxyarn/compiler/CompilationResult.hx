package hxyarn.compiler;

import hxyarn.program.Program;
import hxyarn.dialogue.StringInfo;

class CompilationResult {
	public var program:Program;

	public var stringTable:Map<String, StringInfo>;

	public var declarations:Array<Declaration>;

	public function new() {}

	public static function combineCompilationResults(results:Array<CompilationResult>, stringTableManager:StringTableManager):CompilationResult {
		var programs = new Array<Program>();
		var declarations:Array<Declaration> = new Array<Declaration>();
		// TODO FileTags
		// TODO Diagnostics

		for (result in results) {
			programs.push(result.program);

			if (result.declarations != null)
				declarations.concat(result.declarations);
		}

		var newResults = new CompilationResult();
		newResults.program = Program.combine(programs);
		newResults.stringTable = stringTableManager.stringTable;

		return newResults;
	}
}
