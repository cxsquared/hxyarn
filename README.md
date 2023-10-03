# hxyarn

A Haxe port of [Yarn Spinner](https://github.com/YarnSpinnerTool/YarnSpinner)

This is currently a work in progress though the major functionality has been implemented. I've got most of V2.1 implemented...probably...

Most of the non-Unity specific [documentation on the Yarn Spinner website](https://docs.yarnspinner.dev/) is valid for this library in some fashion.

Feel free to support the main YarnSpinner team over on [Patreon](https://www.patreon.com/secretlab)

## Install

You should probably install this from development because I'm not positive this is super stable yet. Once I'm confident it is stable I'll submit it to haxelib

### Development Build

```posh
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
import hxyarn.compiler.CompilationJob;

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

        var compiler = Compiler.compileFile(yarnFile, dialogue.library);
        stringTable = compiler.stringTable;

        dialogue.addProgram(compiler.program);
    }

    public function load(text:String, name:String) {
        var job = CompilationJob.createFromStrings(texts, names, dialogue.library);
        var compiler = Compiler.compile(job);
        stringTable = compiler.stringTable;

        dialogue.addProgram(compiler.program);
    }

    public function runNode(nodeName:String) {
        dialogue.setNode(nodeName);
        dialogue.resume();
    }

    public function unload() {
        dialogue.unloadAll();
    }

    public function resume() {
        dialogue.resume();
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

You can register custom functions like `<<call hello_world()>>` and `<<call camera_shake(1.5)>>` to be called from your yarn files. Due to implementation details all functions must take in an array of hxyarn.program.Values even if it doesn't expect any and must return an object. Valid return types are `Bool`, `Float`, `String`, and `Null`.

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

### Hot Reload

If you are using [Heaps](https://heaps.io/) you can hot reload your .yarn files. This only works if you are using local resources and not embedded resources.

```haxe
hxd.Res.initLocal();

var manager = new DialogueManager(sceneEventBus);
manager.load(hxd.Res.yarnfile.entry.getText(), hxd.Res.yarnfile.name);

hxd.Res.yarnfile.watch(function() {
    manager.stop();
    manager.unload();
    manager.load(hxd.Res.yarnfile.entry.getText(), hxd.Res.yarnfile.name);
});
```

## Known Issues/Not Implemented

- Error handling is very much lacking
- Missing built in functions: `round_places`, `decimal`
- Two failing unit tests:
  - `Identifies.yarn` - Issue with "fun" characters
- Lacking support for emojis and most non latin unicode characters
- No localization support
