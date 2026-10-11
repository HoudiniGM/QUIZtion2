import 'package:flutter_test/flutter_test.dart';
import 'package:quiztion/domain/answer_option.dart';
import 'package:quiztion/domain/difficulty.dart';
import 'package:quiztion/domain/question.dart';
import 'package:quiztion/domain/question_validation.dart';

AnswerOption opt(String id, {bool correct = false, String? text}) =>
    AnswerOption(
      id: id,
      text: text ?? 'Text $id',
      explanation: 'Explanation $id',
      correct: correct,
    );

Question validQuestion() => Question(
      id: 'q1',
      theme: 'Java',
      subtopic: 'Collections',
      statement: 'Qual implementação de List mantém a ordem de inserção?',
      options: [
        opt('a', correct: true),
        opt('b'),
        opt('c'),
        opt('d'),
      ],
      difficulty: Difficulty.basic,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  group('QuestionValidation', () {
    test('accepts a well-formed question', () {
      final r = QuestionValidation.validate(validQuestion());
      expect(r.valid, isTrue);
      expect(r.errors, isEmpty);
    });

    test('rejects a question with the wrong number of options', () {
      final q = validQuestion()
          .copyWith(options: [opt('a', correct: true), opt('b'), opt('c')]);
      final r = QuestionValidation.validate(q);
      expect(r.valid, isFalse);
      expect(r.errors.any((e) => e.contains('4 alternativas')), isTrue);
    });

    test('rejects a question without exactly one correct option (zero)', () {
      final q = validQuestion()
          .copyWith(options: [opt('a'), opt('b'), opt('c'), opt('d')]);
      final r = QuestionValidation.validate(q);
      expect(r.valid, isFalse);
      expect(r.errors.any((e) => e.contains('1 alternativa correta')), isTrue);
    });

    test('rejects a question with more than one correct option', () {
      final q = validQuestion().copyWith(options: [
        opt('a', correct: true),
        opt('b', correct: true),
        opt('c'),
        opt('d'),
      ]);
      final r = QuestionValidation.validate(q);
      expect(r.valid, isFalse);
      expect(r.errors.any((e) => e.contains('1 alternativa correta')), isTrue);
    });

    test('rejects a question missing an explanation on some option', () {
      final q = validQuestion().copyWith(options: [
        const AnswerOption(
            id: 'a', text: 'A', explanation: '', correct: true),
        opt('b'),
        opt('c'),
        opt('d'),
      ]);
      final r = QuestionValidation.validate(q);
      expect(r.valid, isFalse);
      expect(r.errors.any((e) => e.contains('explicação')), isTrue);
    });

    test('rejects an empty statement', () {
      final q = validQuestion().copyWith(statement: '   ');
      expect(QuestionValidation.isValid(q), isFalse);
    });

    test('rejects a missing theme or subtopic', () {
      expect(QuestionValidation.isValid(validQuestion().copyWith(theme: '')),
          isFalse);
      expect(
          QuestionValidation.isValid(validQuestion().copyWith(subtopic: ' ')),
          isFalse);
    });

    test('rejects nearly identical options', () {
      final q = validQuestion().copyWith(options: [
        opt('a', correct: true, text: 'ArrayList'),
        opt('b', text: '  arraylist '),
        opt('c'),
        opt('d'),
      ]);
      final r = QuestionValidation.validate(q);
      expect(r.valid, isFalse);
      expect(r.errors.any((e) => e.contains('duplicadas')), isTrue);
    });

    test('rejects duplicate option identifiers', () {
      final q = validQuestion().copyWith(options: [
        opt('a', correct: true),
        opt('a', text: 'other'),
        opt('c'),
        opt('d'),
      ]);
      final r = QuestionValidation.validate(q);
      expect(r.valid, isFalse);
      expect(r.errors.any((e) => e.contains('identificadores')), isTrue);
    });
  });
}
