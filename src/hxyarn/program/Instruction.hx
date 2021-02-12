package src.hxyarn.program;

class Instruction {
	public var opcode:OpCode;
	public var operands:Array<Operand>;
}

enum OpCode {
	JUMP_TO;
	JUMP;
	RUN_LINE;
	RUN_COMMAND;
	ADD_OPTIONS;
	SHOW_OPTIONS;
	PUSH_STRING;
	PUSH_FLOAT;
	PUSH_BOOL;
	PUSH_NULL;
	JUMP_IF_FALSE;
	POP;
	CALL_FUNC;
	PUSH_VARIABLE;
	STORE_VARIABLE;
	STOP;
	RUN_NODE;
}
