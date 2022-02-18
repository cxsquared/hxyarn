package hxyarn.dialogue;

class OptionSet {
	public function new(options:Array<Option>) {
		this.options = options;
	}

	public var options(default, set):Array<Option>;

	function set_options(newOptions) {
		return options = newOptions;
	}
}
