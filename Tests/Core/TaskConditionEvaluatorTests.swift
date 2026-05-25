//  TaskConditionEvaluatorTests.swift

import Foundation
import Testing
@testable import LucaCore
@testable import PipelineCore

struct TaskConditionEvaluatorTests {

    private let sut = TaskConditionEvaluator()

    // MARK: - Equality

    @Test
    func test_evaluate_equalityMatch_returnsTrue() {
        #expect(sut.evaluate(condition: "release == release", context: [:]) == true)
    }

    @Test
    func test_evaluate_equalityNoMatch_returnsFalse() {
        #expect(sut.evaluate(condition: "debug == release", context: [:]) == false)
    }

    @Test
    func test_evaluate_equalityWithSubstitution_match_returnsTrue() {
        #expect(sut.evaluate(condition: "${flavor} == release", context: ["flavor": "release"]) == true)
    }

    @Test
    func test_evaluate_equalityWithSubstitution_noMatch_returnsFalse() {
        #expect(sut.evaluate(condition: "${flavor} == release", context: ["flavor": "debug"]) == false)
    }

    // MARK: - Inequality

    @Test
    func test_evaluate_inequalityMatch_returnsTrue() {
        #expect(sut.evaluate(condition: "debug != release", context: [:]) == true)
    }

    @Test
    func test_evaluate_inequalityNoMatch_returnsFalse() {
        #expect(sut.evaluate(condition: "release != release", context: [:]) == false)
    }

    @Test
    func test_evaluate_inequalityWithSubstitution_match_returnsTrue() {
        #expect(sut.evaluate(condition: "${flavor} != release", context: ["flavor": "debug"]) == true)
    }

    @Test
    func test_evaluate_inequalityWithSubstitution_noMatch_returnsFalse() {
        #expect(sut.evaluate(condition: "${flavor} != release", context: ["flavor": "release"]) == false)
    }

    // MARK: - Presence (plain truthy)

    @Test
    func test_evaluate_plainNonEmpty_returnsTrue() {
        #expect(sut.evaluate(condition: "somevalue", context: [:]) == true)
    }

    @Test
    func test_evaluate_plainEmpty_returnsFalse() {
        #expect(sut.evaluate(condition: "", context: [:]) == false)
    }

    @Test
    func test_evaluate_plainFalseString_returnsFalse() {
        #expect(sut.evaluate(condition: "false", context: [:]) == false)
    }

    @Test
    func test_evaluate_plainZeroString_returnsFalse() {
        #expect(sut.evaluate(condition: "0", context: [:]) == false)
    }

    @Test
    func test_evaluate_plainNoString_returnsFalse() {
        #expect(sut.evaluate(condition: "no", context: [:]) == false)
    }

    @Test
    func test_evaluate_plainTrueString_returnsTrue() {
        #expect(sut.evaluate(condition: "true", context: [:]) == true)
    }

    @Test
    func test_evaluate_plainWithSubstitution_nonEmpty_returnsTrue() {
        #expect(sut.evaluate(condition: "${run_integration}", context: ["run_integration": "yes"]) == true)
    }

    @Test
    func test_evaluate_plainWithSubstitution_falsy_returnsFalse() {
        #expect(sut.evaluate(condition: "${run_integration}", context: ["run_integration": "false"]) == false)
    }

    // MARK: - Token substitution

    @Test
    func test_evaluate_unknownToken_resolvesToEmpty_returnsFalse() {
        #expect(sut.evaluate(condition: "${unknown}", context: [:]) == false)
    }

    @Test
    func test_evaluate_unknownTokenInEquality_returnsFalse() {
        #expect(sut.evaluate(condition: "${unknown} == something", context: [:]) == false)
    }

    // MARK: - Whitespace trimming

    @Test
    func test_evaluate_equalityWithLeadingTrailingSpaces_returnsTrue() {
        #expect(sut.evaluate(condition: "  release  ==  release  ", context: [:]) == true)
    }

    // MARK: - Edge cases (malformed expression)

    @Test
    func test_evaluate_malformedExpression_treatedAsPlainString() {
        // No recognised operator — treated as plain truthy after substitution
        #expect(sut.evaluate(condition: "some random text", context: [:]) == true)
    }
}
