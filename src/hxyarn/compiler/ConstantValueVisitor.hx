package hxyarn.compiler;

import hxyarn.compiler.Value.ValueFalse;
import hxyarn.compiler.Value.ValueTrue;
import hxyarn.compiler.Value.ValueString;
import hxyarn.compiler.Value.ValueNumber;
import hxyarn.program.types.BuiltInTypes;
import hxyarn.compiler.Value.ValueNull;
import hxyarn.program.types.IType;
import hxyarn.compiler.Stmt.StmtDeclare;

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
		return new hxyarn.program.Value(BuiltInTypes.undefined, null);
	}

	public override function visitValueNumber(value:ValueNumber):Dynamic {
		return new hxyarn.program.Value(Std.parseFloat(value.literal), BuiltInTypes.number);
	}

	public override function visitValueString(value:ValueString):Dynamic {
		return new hxyarn.program.Value(StringTools.trim(value.literal), BuiltInTypes.string);
	}

	public override function visitValueTrue(value:ValueTrue):Dynamic {
		return new hxyarn.program.Value(true, BuiltInTypes.boolean);
	}

	public override function visitValueFalse(value:ValueFalse):Dynamic {
		return new hxyarn.program.Value(false, BuiltInTypes.boolean);
	}
}
