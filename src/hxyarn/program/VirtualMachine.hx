package src.hxyarn.program;

import src.hxyarn.dialogue.DialogueExcpetion.DialogueException;
import src.hxyarn.dialogue.Line;
import src.hxyarn.dialogue.Option;
import src.hxyarn.dialogue.OptionSet;
import src.hxyarn.dialogue.Command;
import haxe.Exception;
import src.hxyarn.dialogue.Dialogue;

class VirtualMachine {
	var dialogue:Dialogue;
	var state = new State();

	public var program:Program;

	public var lineHandler:LineHandler;
	public var optionsHandler:OptionsHandler;
	public var commandHandler:CommandHandler;
	public var nodeStartHandler:NodeStartHanlder;
	public var nodeCompleteHandler:NodeCompleteHandler;
	public var dialogueCompleteHandler:DialogueCompleteHandler;
	public var prepareForLinesHandler:PrepareForLinesHandler;

	public var executionState(default, set):ExecutionState;

	function set_executionState(newExecutionState) {
		if (newExecutionState == ExecutionState.Stopped) {
			resetState();
		}

		return executionState = newExecutionState;
	}

	var currentNode:Node;

	public function new(d:Dialogue) {
		dialogue = d;
	}

	public function currentNodeName():String {
		return state.currentNodeName;
	}

	public function setNode(nodeName:String):Bool {
		if (program == null || !program.nodes.iterator().hasNext()) {
			throw new DialogueException('Cannot load node $nodeName: No nodes have been loaded.');
		}

		if (program.nodes.exists(nodeName) == false) {
			executionState = Stopped;
			throw new DialogueException('No node named $nodeName has been loaded.');
		}

		dialogue.logDebugMessage('Running node $nodeName');

		currentNode = program.nodes.get(nodeName);
		resetState();
		state.currentNodeName = nodeName;

		if (nodeStartHandler != null)
			nodeStartHandler(nodeName);

		return true;
	}

	public function stop() {
		executionState = Stopped;
	}

	public function setSelectedOption(selectedOptionId:Int) {
		if (executionState != WaitingOnOptionSelection) {
			throw new DialogueException("SetSelectedOption was called, but Dialogue wasn't waiting for a selection. This method should only be called after the Dialogue is waiting for the user to select an option.");
		}

		if (selectedOptionId < 0 || selectedOptionId >= state.currentOptions.length) {
			throw new Exception('$setSelectedOption is not a valid option Id (expected a number btween 0 and ${state.currentOptions.length})');
		}

		var destinationNode = state.currentOptions[selectedOptionId].value;
		state.PushValue(destinationNode);

		state.clearOptions();

		executionState = WaitingForContinue;
	}

	public function contiune() {
		checkCanContinue();

		if (executionState == DeliveringContent) {
			executionState = Running;
			return;
		}

		executionState = Running;

		while (executionState == Running) {
			var currentInstruction = currentNode.instructions[state.programCounter];

			runInstruction(currentInstruction);

			state.programCounter++;

			if (state.programCounter >= currentNode.instructions.length) {
				nodeCompleteHandler(currentNode.name);
				executionState = Stopped;
				dialogueCompleteHandler();
				dialogue.logDebugMessage("Run complete");
			}
		}
	}

	function checkCanContinue() {
		if (currentNode == null) {
			throw new DialogueException("Cannot continue running dialogue. No node has been selected.");
		}

		if (executionState == WaitingOnOptionSelection) {
			throw new DialogueException("Cannot continue running dialogue. Still waiting on option selection.");
		}

		if (lineHandler == null) {
			throw new DialogueException("Cannot continue running dialogue. lineHandler has not been set.");
		}

		if (optionsHandler == null) {
			throw new DialogueException("Cannot continue running dialogue. optionsHandler has not been set.");
		}

		if (commandHandler == null) {
			throw new DialogueException("Cannot continue running dialogue. commandHandler has not been set.");
		}

		if (nodeCompleteHandler == null) {
			throw new DialogueException("Cannot continue running dialogue. nodeCompleteHandler has not been set.");
		}

		if (dialogueCompleteHandler == null) {
			throw new DialogueException("Cannot continue running dialogue. dialougeCompleteHandler has not been set.");
		}
	}

	function findInstructionPointForLabel(labelName:String):Int {
		if (currentNode.labels.exists(labelName) == false) {
			throw new Exception('Unknown label $labelName in node ${state.currentNodeName}');
		}

		return currentNode.labels[labelName];
	}

	function runInstruction(i:Instruction) {
		switch (i.opcode) {
			case JUMP_TO:
				state.programCounter = findInstructionPointForLabel(i.operands[0].stringValue) - 1;
			case RUN_LINE:
				var stringKey = i.operands[0].stringValue;
				var line = new Line(stringKey);

				if (i.operands.length > 1) {
					var expressionCount = Std.int(i.operands[1].floatValue);

					var strings = [];

					if (expressionCount > 0) {
						var expressionIndex = expressionCount - 1;
						while (expressionIndex >= 0) {
							strings[expressionIndex] = state.PopValue().asString();
							expressionIndex--;
						}
					}

					line.substitutions = strings;
				}

				executionState = DeliveringContent;

				lineHandler(line);

				if (executionState == DeliveringContent) {
					executionState = WaitingForContinue;
				}
			case RUN_COMMAND:
				var commandText = i.operands[0].stringValue;

				if (i.operands.length > 0) {
					var expressionCount = Std.int(i.operands[1].floatValue);

					for (expressionIndex in 0...expressionCount) {
						var substituation = state.PopValue().asString();

						commandText = StringTools.replace(commandText, '{$expressionIndex}', substituation);
					}
				}

				executionState = DeliveringContent;

				var command = new Command(commandText);

				commandHandler(command);

				if (executionState == DeliveringContent) {
					executionState = WaitingForContinue;
				}
			case PUSH_STRING:
				state.PushValue(i.operands[0].stringValue);
			case PUSH_FLOAT:
				state.PushValue(i.operands[0].floatValue);
			case PUSH_BOOL:
				state.PushValue(i.operands[0].boolValue);
			case PUSH_NULL:
				state.PushValue(Value.NULL);
			case JUMP_IF_FALSE:
				if (state.PeekValue().asBool() == false) {
					state.programCounter = findInstructionPointForLabel(i.operands[0].stringValue) - 1;
				}
			case JUMP:
				var jumpDestination = state.PeekValue().asString();
				state.programCounter = findInstructionPointForLabel(jumpDestination) - 1;
			case POP:
				state.PopValue();
			case CALL_FUNC:
				var functionName = i.operands[0].stringValue;

				var func = dialogue.library.getFunction(functionName);

				var expectedParamCount = func.paramCount;

				var actualParamCount = Std.int(state.PopValue().asNumber());

				if (expectedParamCount == -1) {
					expectedParamCount = actualParamCount;
				}

				if (expectedParamCount != actualParamCount) {
					throw new Exception('Function ${func.name} expected $expectedParamCount, but received $actualParamCount');
				}

				var result:Value;
				if (actualParamCount == 0) {
					result = func.invoke(null);
				} else {
					var parameters = new Array<Value>();
					for (param in 0...actualParamCount) {
						parameters[actualParamCount - 1 - param] = state.PopValue();
					}

					result = func.invokeWithArray(parameters);
				}

				if (func.returnsValue())
					state.PushValue(result);

			case PUSH_VARIABLE:
				var variableName = i.operands[0].stringValue;
				var loadedValue = dialogue.variableStorage.getValue(variableName);
				state.PushValue(loadedValue);
			case STORE_VARIABLE:
				var topValue = state.PeekValue();
				var destinationVariableName = i.operands[0].stringValue;
				dialogue.variableStorage.setValue(destinationVariableName, topValue);
			case STOP:
				nodeCompleteHandler(currentNode.name);
				dialogueCompleteHandler();
				executionState = Stopped;
			case RUN_NODE:
				var nodeName = state.PopValue().asString();

				nodeCompleteHandler(currentNode.name);

				setNode(nodeName);

				state.programCounter -= 1;
			case ADD_OPTIONS:
				var stringKey = i.operands[0].stringValue;
				var line = new Line(stringKey);

				if (i.operands.length > 2) {
					var expressionCount = Std.int(i.operands[2].floatValue);

					var strings = [];

					if (expressionCount > 0) {
						var expressionIndex = expressionCount - 1;
						while (expressionIndex >= 0) {
							strings[expressionIndex] = state.PopValue().asString();
							expressionIndex--;
						}
					}

					line.substitutions = strings;
				}

				var lineConditionPassed = true;
				if (i.operands.length > 3) {
					var hasLineCondition = i.operands[3].boolValue;

					if (hasLineCondition) {
						lineConditionPassed = state.PopValue().asBool();
					}
				}

				var destination = i.operands[1].stringValue;

				state.currentOptions.push({line: line, value: destination, enabled: lineConditionPassed});
			case SHOW_OPTIONS:
				if (state.currentOptions.length == 0) {
					executionState = Stopped;
					dialogueCompleteHandler();
					return;
				}

				var optionChoices = new Array<Option>();

				for (optionIndex => option in state.currentOptions) {
					optionChoices.push(new Option(option.line, optionIndex, option.value, option.enabled));
				}

				executionState = WaitingOnOptionSelection;
				optionsHandler(new OptionSet(optionChoices));

				if (executionState == WaitingOnOptionSelection) {
					executionState = Running;
				}
			case _:
				executionState = Stopped;
				throw new Exception('Unknow opcode ${i.opcode}');
		}
	}

	public function resetState() {
		state = new State();
	}
}

enum ExecutionState {
	Stopped;
	WaitingOnOptionSelection;
	WaitingForContinue;
	DeliveringContent;
	Running;
}

enum TokenType {
	// Special tokens
	Whitespace;
	Indent;
	Dedent;
	EndOfLine;
	EndOfInput;

	// Numbers. Everybody loves a number
	Number;
	// Strings. Everybody also loves a string
	String;
	// '#'
	TagMarker;
	// Command syntax ("<<foo>>")
	BeginCommand;
	EndCommand;
	// Variables ("$foo")
	Variable;
	// Shortcut syntax ("->")
	ShortcutOption;
	// Option syntax ("[[Let's go here|Destination]]")
	OptionStart; // [[
	OptionDelimit; // |
	OptionEnd; // ]]
	// Command types (specially recognised command word)
	If;
	ElseIf;
	Else;
	EndIf;
	Set;
	// Boolean values
	True;
	False;
	// The null value
	Null;
	// Parentheses
	LeftParen;
	RightParen;
	// Parameter delimiters
	Comma;
	// Operators
	EqualTo; // ==; eq; is
	GreaterThan; // >; gt
	GreaterThanOrEqualTo; // >=; gte
	LessThan; // <; lt
	LessThanOrEqualTo; // <=; lte
	NotEqualTo; // !=; neq
	// Logical operators
	Or; // ||; or
	And; // &&; and
	Xor; // ^; xor
	Not; // !; not
	// this guy's special because '=' can mean either 'equal to'
	// or 'becomes' depending on context
	EqualToOrAssign; // =; to
	UnaryMinus; // -; this is differentiated from Minus
	// when parsing expressions
	Add; // +
	Minus; // -
	Multiply; // *
	Divide; // /
	Modulo; // %
	AddAssign; // +=
	MinusAssign; // -=
	MultiplyAssign; // *=
	DivideAssign; // /=
	Comment; // a run of text that we ignore
	Identifier; // a single word (used for functions)
	Text; // a run of text until we hit other syntax
}
