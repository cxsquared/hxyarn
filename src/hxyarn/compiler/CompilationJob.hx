package hxyarn.compiler;

import hxyarn.program.Library;

class CompilationJob {
	public var files:Array<FileInfo>;
	public var library:Library;
	public var type:CompilationType;
	public var variableDelarations:Array<Declaration>;

	public static function createFromFiles(files:Array<String>, ?libray:Library):CompilationJob {
		var fileList = new Array<FileInfo>();

		for (file in files) {
			fileList.push(new FileInfo(file, sys.io.File.getContent(file)));
		}

		var job = new CompilationJob();
		job.files = fileList;
		job.library = libray;

		return job;
	}

	public static function createFromStrings(strings:Array<String>, fileNames:Array<String>, ?libray:Library):CompilationJob {
		if (strings.length != fileNames.length)
			throw 'Number of strings and file names must be equal';

		var fileList = new Array<FileInfo>();

		for (i => s in strings) {
			fileList.push(new FileInfo(fileNames[i], s));
		}

		var job = new CompilationJob();
		job.files = fileList;
		job.library = libray;

		return job;
	}

	private function new() {}
}

class FileInfo {
	public var fileName:String;
	public var source:String;

	public function new(fileName:String, source:String) {
		this.fileName = fileName;
		this.source = source;
	}
}

enum CompilationType {
	FullCompilation;
}
