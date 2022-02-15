package tests;

import sys.io.File;
import haxe.Exception;

class TestPlan {
	var steps = new Array<Step>();
	var currentTestPlanStep = 0;

	public var nextExpectedType:StepType;
	public var nextExpectedOptions = new Array<String>();
	public var nextOptionToSelect = -1;
	public var nextExpectedValue:String = null;
	public var path:String;

	public function new(path:String) {
		this.path = path;
		var source = File.getContent(path);

		for (line in source.split('\n')) {
			line = StringTools.trim(line);
			if (StringTools.trim(line).indexOf('#') == 0)
				continue;

			if (StringTools.trim(line).length <= 0)
				continue;

			steps.push(new Step(line));
		}
	}

	public function next() {
		if (nextExpectedType == StepType.Select) {
			nextExpectedOptions = new Array<String>();
			nextOptionToSelect = 0;
		}

		var stop = false;
		while (currentTestPlanStep < steps.length && !stop) {
			var currentStep = steps[currentTestPlanStep];

			currentTestPlanStep += 1;

			switch (currentStep.type) {
				case Line:
					nextExpectedType = currentStep.type;
					nextExpectedValue = currentStep.stringValue;
					stop = true;
				case Option:
					nextExpectedOptions.push(currentStep.stringValue);
					continue;
				case Select:
					nextExpectedType = currentStep.type;
					nextOptionToSelect = currentStep.intValue;
					stop = true;
				case Command:
					nextExpectedType = currentStep.type;
					nextExpectedValue = currentStep.stringValue;
					stop = true;
				case Stop:
					nextExpectedType = currentStep.type;
					nextExpectedValue = currentStep.stringValue;
					stop = true;
			}
		}

		if (!stop) {
			nextExpectedType = Stop;
		}
	}
}

class Step {
	public var type:StepType;

	public var stringValue:String;
	public var intValue:Int;

	public function new(s:String) {
		intValue = -1;
		stringValue = null;

		var reader = new Reader(s);

		try {
			type = reader.readNext(Line);

			var delimiter = reader.read();
			if (delimiter != ":") {
				throw new Exception("Expected ':' after step type");
			}

			switch (type) {
				case Line:
					stringValue = StringTools.trim(reader.readTillEnd());
					if (stringValue == "*") {
						stringValue = null;
					}
				case Option:
					stringValue = StringTools.trim(reader.readTillEnd());
					if (stringValue == "*") {
						stringValue = null;
					}
				case Command:
					stringValue = StringTools.trim(reader.readTillEnd());
					if (stringValue == "*") {
						stringValue = null;
					}
				case Select:
					intValue = reader.readNext(0);

					if (intValue < 1)
						throw new Exception('Cannot select option $intValue - must be >= 1');
				case _:
			}
		} catch (e:Exception) {
			throw new Exception('Failed to parse step line: "$s" (reason: ${e.message})', e);
		}
	}
}

class Reader {
	var source:String;
	var start:Int = 0;
	var current:Int = 0;

	var isWhiteSpace = ~/\s/;
	var isAlphaNumeric = ~/[a-zA-Z0-9]/;

	public function new(s:String) {
		source = s;
	}

	public function read():String {
		var char = source.charAt(start);
		start++;
		return char;
	}

	public function readTillEnd():String {
		var text = source.substr(start, source.length - start);
		start = source.length - 1;
		return text;
	}

	public function readNext(any:Dynamic):Dynamic {
		do {
			var char = source.charAt(current);
			current++;

			if (isWhiteSpace.match(char)) {
				start = current;
				current++;
				continue;
			}

			var next = source.charAt(current + 1);
			if (!isAlphaNumeric.match(next)) {
				current++;
				break;
			}
		} while (true);

		var value = source.substr(start, current - start);
		start = current;

		if (Std.isOfType(any, StepType))
			return StepType.createByName(uperCaseStart(value));

		if (Std.isOfType(any, Int))
			return Std.parseInt(value);

		return value;
	}

	function uperCaseStart(s:String):String {
		return s.substr(0, 1).toUpperCase() + s.substr(1);
	}
}

enum StepType {
	Line;
	Option;
	Select;
	Command;
	Stop;
}
