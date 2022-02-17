# hxyarn

A Haxe port of [Yarn Spinner](https://github.com/YarnSpinnerTool/YarnSpinner)

This is currently a work in progress though the major functionality has been implemented.

## Install

### Standard

```sh
haxelib git https://github.com/cxsquared/hxyarn.git
```

## Usage

```haxe

import hxyarn.dialogue.Dialogue;
import hxyarn.dialogue.VariableStorage.MemoryVariableStore;
import hxyarn.dialogue.StringInfo;
import hxyarn.dialogue.Line;
import hxyarn.dialogue.Command;
import hxyarn.dialogue.Option;
import hxyarn.dialogue.OptionSet;
import hxyarn.compiler.Compiler;

class DialogueExample {
    var storage = new MemoryVariableStore();
    var dialogue:Dialogue;
    var stringTable:Map<String, StringInfo>;

    public function new(yarnFile:String) {
        dialogue = new Dialogue(new MemoryVariableStore());

        dialogue.logDebugMessage = this.logDebugMessage;
        dialogue.logErrorMessage = this.logErrorMessage;
        dialogue.lineHandler = this.lineHandler;
        dialogue.optionsHandler = this.optionsHandler;
        dialogue.commandHandler = this.commandHandler;
        dialogue.nodeCompleteHandler = this.nodeCompleteHandler;
        dialogue.nodeStartHandler = this.nodeStartHandler;
        dialogue.dialogueCompleteHandler = this.dialogueCompleteHandler;

        var compiler = Compiler.compileFile(yarnFile);
        stringTable = compiler.stringTable;

        dialogue.addProgram(compiler.program);
    }

    public function start() {
        dialogue.setNode("Start");

        do {
            dialogue.resume();
        } while (dialogue.isActive());
    }

    public function logDebugMessage(message:String):Void {
    }

    public function logErrorMessage(message:String):Void {
    }

    public function lineHandler(line:Line):HandlerExecutionType {
        var text = getComposedTextForLine(line);

        // Show text

        return HandlerExecutionType.ContinueExecution;
    }

    public function optionsHandler(options:OptionSet) {
        var optionCount = options.options.length;
        var optionText = new Array<String>();

        for (option in options.options) {
            var text = getComposedTextForLine(option.line);
            optionText.push(text);
        }

        // show options
    }

    public function getComposedTextForLine(line:Line):String {
        var substitutedText = Dialogue.expandSubstitutions(stringTable[line.id].text, line.substitutions);

        var markup = dialogue.parseMarkup(substitutedText);

        return markup.text;
    }

    public function commandHandler(command:Command) {
    }

    public function nodeCompleteHandler(nodeName:String) {}

    public function nodeStartHandler(nodeName:String) {}

    public function dialogueCompleteHandler() {
    }
}
```

## Known Issues

- Lacking support for emojis and most non latin unicode characters
