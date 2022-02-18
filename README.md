# hxyarn

A Haxe port of [Yarn Spinner](https://github.com/YarnSpinnerTool/YarnSpinner)

This is currently a work in progress though the major functionality has been implemented.

## Install

### Standard

```sh
haxelib git hxyarn https://github.com/cxsquared/hxyarn.git
```

## Usage

### Example

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

### Custom Functions

You can register custom functions like ```<<hello_world>>``` and ```<<camera_shake 1.5>>``` to be called from your yarn files. Due to implementation details all functions must take in an array of hxyarn.program.Values even if it doesn't expect any and must return an object. Valid return types are ```Bool```, ```Float```, ```String```, and ```Null```.

```haxe
import hxyarn.program.types.BuiltInTypes;
import hxyarn.program.Value;

dialogue.library.registerFunction("hello_world", 0, function(values:Array<Value>) {
    return "Hello World!";
}, BuiltInTypes.string);

dialogue.library.registerFunction("camera_shake", 1, function(values:Array<Value>) {
    var shakeTime = values[0].asNumber();
    trace('Shaking camera for $shakeTime seconds');
    return null;
});
```

## Known Issues

- Lacking support for emojis and most non latin unicode characters
