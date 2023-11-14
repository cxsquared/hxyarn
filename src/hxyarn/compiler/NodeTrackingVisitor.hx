package hxyarn.compiler;

import hxyarn.compiler.Stmt.StmtNode;
import hxyarn.compiler.Value.ValueString;
import hxyarn.compiler.Value.ValueFunctionCall;

class NodeTrackingVisitor extends BaseVisitor {
	var TrackingNodes:Array<String>;
	var NeverVisitNodes:Array<String>;

	public function new(existingTrackingNodes:Array<String>, existingBlockedNodes:Array<String>) {
		this.TrackingNodes = existingTrackingNodes;
		this.NeverVisitNodes = existingBlockedNodes;
	}

	public override function visitValueFunctionCall(value:ValueFunctionCall):Dynamic {
		var functionName = value.functionId.lexeme;

		if (functionName == "visited" || functionName == "visited_count") {
			// we aren't bothering to test anything about the value itself
			// if it isn't a static string we'll get back null so can ignore it
			// if the func has more than one parameter later on it will cause an error so again can ignore
			var result = value.expressions[0].accept(this);

			if (result != null) {
				TrackingNodes.push(result);
			}
		}

		return null;
	}

	public override function visitValueString(value:ValueString):Dynamic {
		return StringTools.trim(value.value.literal);
	}

	public override function visitNode(stmt:StmtNode):Dynamic {
		var title:String = null;
		var tracking:String = null;
		for (header in stmt.headers) {
			var headerKey = header.id;
			if (headerKey.lexeme == "title") {
				title = header.value.lexeme;
			} else if (headerKey.lexeme == "tracking") {
				tracking = header.value.lexeme;
			}
		}

		if (title != null && tracking != null) {
			if (tracking == "always") {
				TrackingNodes.push(title);
			} else if (tracking == "never") {
				NeverVisitNodes.push(title);
			}
		}

		if (stmt.body != null) {
			return stmt.body.accept(this);
		}

		return null;
	}
}
