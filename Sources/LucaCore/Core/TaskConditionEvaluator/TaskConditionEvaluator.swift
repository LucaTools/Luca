//  TaskConditionEvaluator.swift

/// Evaluates `when:` condition expressions for pipeline tasks.
///
/// Three expression forms are supported:
/// - `LHS == RHS` — true when both sides are equal after trimming.
/// - `LHS != RHS` — true when both sides differ after trimming.
/// - plain string — true when non-empty and not in `["false", "0", "no"]`.
///
/// `${name}` tokens are substituted from the provided context before evaluation.
/// Unknown tokens resolve to an empty string.
public struct TaskConditionEvaluator: TaskConditionEvaluating {

    public init() {}

    // MARK: - TaskConditionEvaluating

    public func evaluate(condition: String, context: [String: String]) -> Bool {
        let substituted = substitute(condition, context: context)

        if let (lhs, rhs) = split(substituted, op: "==") {
            return lhs == rhs
        }
        if let (lhs, rhs) = split(substituted, op: "!=") {
            return lhs != rhs
        }
        return isTruthy(substituted.trimmingCharacters(in: .whitespaces))
    }

    // MARK: - Private

    private func substitute(_ expression: String, context: [String: String]) -> String {
        let substituted = context.reduce(expression) { result, pair in
            result.replacingOccurrences(of: "${\(pair.key)}", with: pair.value)
        }
        // Replace any remaining unresolved ${...} tokens with empty string
        return substituted.replacingOccurrences(of: #"\$\{[^}]*\}"#, with: "", options: .regularExpression)
    }

    private func split(_ expression: String, op: String) -> (String, String)? {
        let parts = expression.components(separatedBy: op)
        guard parts.count == 2 else { return nil }
        return (parts[0].trimmingCharacters(in: .whitespaces),
                parts[1].trimmingCharacters(in: .whitespaces))
    }

    private func isTruthy(_ value: String) -> Bool {
        !value.isEmpty && !["false", "0", "no"].contains(value)
    }
}
