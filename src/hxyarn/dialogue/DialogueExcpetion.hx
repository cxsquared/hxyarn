package hxyarn.dialogue;

import haxe.Exception;

class DialogueException extends Exception {
	public function new(message:String, ?previous:Exception, ?native:Null<Any>) {
		super(message, previous, native);
	}
}
