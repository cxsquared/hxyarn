package src.hxyarn.dialogue;

import src.hxyarn.dialogue.markup.MarkupAttributeMarker;
import src.hxyarn.dialogue.markup.IAttributeMarkerProcessor;
import src.hxyarn.dialogue.markup.MarkupParseResult;
import src.hxyarn.program.StandardLibrary;
import src.hxyarn.program.Library;
import src.hxyarn.dialogue.CLDR.PluralCase;
import src.hxyarn.dialogue.DialogueExcpetion.DialogueException;
import src.hxyarn.program.VirtualMachine;
import src.hxyarn.dialogue.OptionSet;
import src.hxyarn.program.Program;

typedef Logger = String->Void;
typedef LineHandler = Line->Void;
typedef OptionsHandler = OptionSet->Void;
typedef CommandHandler = Command->Void;
typedef NodeCompleteHandler = String->Void;
typedef NodeStartHanlder = String->Void;
typedef DialogueCompleteHandler = Void->Void;
typedef PrepareForLinesHandler = Array<String>->Void;

enum HandlerExecutionType {
	PauseExecution;
	ContinueExecution;
}

class Dialogue implements IAttributeMarkerProcessor {
	public var variableStorage:VariableStorage;

	public var logDebugMessage:Logger;
	public var logErrorMessage:Logger;

	public static inline var DEFAULT_START = "Start";

	static inline var formatFunctionValuePlaceHolder = "<VALUE PLACEHOLDER>";

	var program(default, set):Program;

	function set_program(newProgram) {
		vm.program = newProgram;
		vm.resetState();

		return program = newProgram;
	}

	var vm:VirtualMachine;

	public function isActive() {
		return vm.executionState != ExecutionState.Stopped;
	}

	public var lineHandler(get, set):LineHandler;
	public var optionsHandler(get, set):OptionsHandler;
	public var commandHandler(get, set):CommandHandler;
	public var nodeStartHandler(get, set):NodeStartHanlder;
	public var nodeCompleteHandler(get, set):NodeCompleteHandler;
	public var dialogueCompleteHandler(get, set):DialogueCompleteHandler;
	public var prepareForLinesHandler(get, set):PrepareForLinesHandler;

	public function get_lineHandler() {
		return vm.lineHandler;
	}

	public function set_lineHandler(newLineHandler) {
		return vm.lineHandler = newLineHandler;
	}

	public function get_optionsHandler() {
		return vm.optionsHandler;
	}

	public function set_optionsHandler(newOptionsHandler) {
		return vm.optionsHandler = newOptionsHandler;
	}

	public function get_commandHandler() {
		return vm.commandHandler;
	}

	public function set_commandHandler(newCommandHandler) {
		return vm.commandHandler = newCommandHandler;
	}

	public function get_nodeStartHandler() {
		return vm.nodeStartHandler;
	}

	public function set_nodeStartHandler(newNodeStartHandler) {
		return vm.nodeStartHandler = newNodeStartHandler;
	}

	public function get_nodeCompleteHandler() {
		return vm.nodeCompleteHandler;
	}

	public function set_nodeCompleteHandler(newNodeCompleteHandler) {
		return vm.nodeCompleteHandler = newNodeCompleteHandler;
	}

	public function get_dialogueCompleteHandler() {
		return vm.dialogueCompleteHandler;
	}

	public function set_dialogueCompleteHandler(newDialogueCopmleteHandler) {
		return vm.dialogueCompleteHandler = newDialogueCopmleteHandler;
	}

	public function get_prepareForLinesHandler() {
		return vm.prepareForLinesHandler;
	}

	public function set_prepareForLinesHandler(newPrepareForLinesHandler) {
		return vm.prepareForLinesHandler = newPrepareForLinesHandler;
	}

	public var library(default, set):Library;

	function set_library(newLibrary) {
		return library = newLibrary;
	}

	var lineParser:LineParser;

	public function new(variableStorage:VariableStorage) {
		if (variableStorage == null)
			throw new DialogueException("Must provide a VariableStorage for a Dialogue");

		this.variableStorage = variableStorage;
		library = new Library();

		this.vm = new VirtualMachine(this);

		library.importLibrary(new StandardLibrary());

		lineParser = new LineParser();

		lineParser.registerMarkerProcessor("select", this);
		lineParser.registerMarkerProcessor("plural", this);
		lineParser.registerMarkerProcessor("ordinal", this);
	}

	public function setProgram(program:Program) {
		this.program = program;
	}

	public function addProgram(program:Program) {
		if (this.program == null) {
			setProgram(program);
			return;
		}

		this.program = Program.combine([this.program, program]);
	}

	public function setNode(?startNode:String = DEFAULT_START) {
		vm.setNode(startNode);
	}

	public function setSelectedOption(selectedOptionId:Int) {
		vm.setSelectedOption(selectedOptionId);
	}

	public function resume() {
		if (vm.executionState == ExecutionState.Running)
			return;

		vm.contiune();
	}

	public function stop() {
		if (vm != null)
			vm.stop();
	}

	public var allNodes(get, null):Iterator<String>;

	public function get_allNodes() {
		return program.nodes.keys();
	}

	public var currentNode(get, null):String;

	public function get_currentNode() {
		if (vm == null)
			return null;

		return vm.currentNodeName();
	}

	public function getStringIdForNode(nodeName:String) {
		if (Lambda.count(program.nodes) == 0) {
			logErrorMessage("No nodes are loaded!");
			return null;
		}

		if (program.nodes.exists(nodeName))
			return 'line: $nodeName';

		logErrorMessage('No node named $nodeName');
		return null;
	}

	public function getTagsForNode(nodeName) {
		if (Lambda.count(program.nodes) == 0) {
			logErrorMessage("No nodes are loaded!");
			return null;
		}

		if (program.nodes.exists(nodeName))
			return program.getTagsForNode(nodeName);

		logErrorMessage('No node named $nodeName');
		return null;
	}

	public function unloadAll() {
		program = null;
	}

	public function nodeExists(nodeName:String):Bool {
		if (program == null) {
			logErrorMessage("Tried to call nodeExists, but no nodes have been compiled!");
			return false;
		}

		if (program.nodes == null || Lambda.count(program.nodes) == 0) {
			logDebugMessage("Called nodeExists, but there are zero nodes. This may be an error.");
			return false;
		}

		return program.nodes.exists(nodeName);
	}

	// TODO
	public function analyse() {}

	public function parseMarkup(line:String):MarkupParseResult {
		return lineParser.parseMarkup(line);
	}

	public static function expandSubstitutions(text:String, substitutions:Array<String>) {
		for (i => substitution in substitutions) {
			text = StringTools.replace(text, '{$i}', substitution);
		}

		return text;
	}

	private static final ValuePlaceholderRegex = new EReg("(?<!\\\\)%", "i");

	public function replacementTextForMarker(marker:MarkupAttributeMarker):String {
		var valueProp = marker.tryGetProperty("value");
		if (valueProp == null)
			throw 'Expected a property "value"';

		var value = valueProp.toString();

		if (marker.name == "select") {
			var replacementProp = marker.tryGetProperty(value);
			if (replacementProp == null)
				throw 'error: no replacment for $value';

			var replacement = replacementProp.toString();
			replacement = ValuePlaceholderRegex.replace(replacement, value);
			return replacement;
		}

		// TODO: Language code
		var languageCode = "en";

		var doubleValue = Std.parseInt(value);
		if (doubleValue == null)
			throw 'error: $value is not a number';

		var pluralCase:PluralCase;

		switch (marker.name) {
			case "plural":
				pluralCase = CLDR.getCardinalPluralCase(languageCode, doubleValue);
			case "ordinal":
				pluralCase = CLDR.getOrdinalPluralCase(languageCode, doubleValue);
			case _:
				throw 'Invalid marker ${marker.name}';
		}

		var pluralCaseName = pluralCase.getName().toLowerCase();

		var replacementValue = marker.tryGetProperty(pluralCaseName);
		if (replacementValue == null)
			throw 'error: no replacment for $pluralCaseName';

		var input = replacementValue.toString();
		return ValuePlaceholderRegex.replace(input, value);
	}
}
