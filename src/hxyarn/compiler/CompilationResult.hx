package hxyarn.compiler;

import hxyarn.program.Program;
import hxyarn.dialogue.StringInfo;

class CompilationResult {
	public var program:Program;

	public var stringTable:Map<String, StringInfo>;

	public var declarations:Array<Declaration>;

	public var tags:Map<String, Array<String>>;

	public function new() {}

	public static function combineCompilationResults(results:Array<CompilationResult>, stringTableManager:StringTableManager):CompilationResult {
		var programs = new Array<Program>();
		var declarations = new Array<Declaration>();
		var tags = new Map<String, Array<String>>();
		// TODO Diagnostics

		for (result in results) {
			programs.push(result.program);

			if (result.declarations != null)
				declarations = declarations.concat(result.declarations);

			if (result.tags != null) {
				for (key => tag in result.tags) {
					tags.set(key, tag);
				}
			}
		}

		var newResults = new CompilationResult();
		newResults.program = Program.combine(programs);
		newResults.stringTable = stringTableManager.stringTable;

		return newResults;
	}
}
