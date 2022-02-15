package src.hxyarn.compiler;

import src.hxyarn.compiler.Value.ValueFalse;
import src.hxyarn.compiler.Value.ValueTrue;
import src.hxyarn.compiler.Value.ValueString;
import src.hxyarn.compiler.Value.ValueNumber;
import src.hxyarn.program.types.BuiltInTypes;
import src.hxyarn.compiler.Value.ValueNull;
import src.hxyarn.program.types.IType;
import src.hxyarn.compiler.Stmt.StmtDeclare;

class ConstantValueVisitor extends BaseVisitor {
	var context:StmtDeclare;
	var sourceFileName:String;
	var types:Array<IType>;

	public function new(context:StmtDeclare, sourceFileName:String, types:Array<IType>) {
		this.context = context;
		this.sourceFileName = sourceFileName;
		this.types = types;
	}

	public override function visitValueNull(value:ValueNull):Dynamic {
		// TODO diagnostics
		return new src.hxyarn.program.Value(BuiltInTypes.undefined, null);
	}

	public override function visitValueNumber(value:ValueNumber):Dynamic {
		return new src.hxyarn.program.Value(Std.parseFloat(value.literal), BuiltInTypes.number);
	}

	public override function visitValueString(value:ValueString):Dynamic {
		return new src.hxyarn.program.Value(StringTools.trim(value.literal), BuiltInTypes.string);
	}

	public override function visitValueTrue(value:ValueTrue):Dynamic {
		return new src.hxyarn.program.Value(true, BuiltInTypes.boolean);
	}

	public override function visitValueFalse(value:ValueFalse):Dynamic {
		return new src.hxyarn.program.Value(false, BuiltInTypes.boolean);
	}
}
