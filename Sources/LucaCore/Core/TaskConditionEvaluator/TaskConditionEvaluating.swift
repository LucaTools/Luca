//  TaskConditionEvaluating.swift

/// Evaluates a `when:` condition expression against a resolved key-value context.
public protocol TaskConditionEvaluating {
    /// Returns `true` if `condition` evaluates to a truthy result using the provided context.
    ///
    /// `${name}` tokens in `condition` are substituted from `context` before evaluation.
    /// Unknown tokens resolve to an empty string.
    func evaluate(condition: String, context: [String: String]) -> Bool
}
