import '../domain/answer_option.dart';
import '../domain/difficulty.dart';
import '../domain/question.dart';
import 'question_repository.dart';

/// Populates the local database, on first run, with a single example theme and
/// a few questions, so the quiz flow works offline out of the box. The user is
/// free to create their own themes and subtopics and to generate more
/// questions by AI.
class DataSeeder {
  final QuestionRepository _repo;

  DataSeeder(this._repo);

  /// Runs the seed only if the database has no questions yet.
  Future<void> seedIfNeeded() async {
    final total = await _repo.countQuestions();
    if (total > 0) return;
    await seed();
  }

  Future<void> seed() async {
    final now = DateTime(2026, 1, 1);

    // A single example theme with three subtopics (pt-BR, user-facing).
    const theme = 'Java Core';
    const subtopics = ['Collections', 'Exceções', 'Lambdas e Streams'];

    await _repo.insertTheme(id: _slug(theme), name: theme, createdAt: now);
    for (final sub in subtopics) {
      await _repo.insertSubtopic(
        id: '${_slug(theme)}__${_slug(sub)}',
        themeId: _slug(theme),
        name: sub,
        createdAt: now,
      );
    }

    for (final q in _exampleQuestions(now)) {
      await _repo.insertQuestion(q);
    }
  }

  List<Question> _exampleQuestions(DateTime now) {
    return [
      // --- Collections — Basic (example from requirements, section 8.1) ---
      Question(
        id: 'seed-collections-basic-1',
        theme: 'Java Core',
        subtopic: 'Collections',
        statement:
            'Qual implementação da interface List permite armazenar elementos '
            'em uma lista redimensionável e mantém a ordem de inserção?',
        difficulty: Difficulty.basic,
        createdAt: now,
        options: const [
          AnswerOption(
            id: 'a',
            text: 'HashSet',
            correct: false,
            explanation:
                'Incorreta. Implementa Set, não List, e não garante a ordem '
                'de inserção.',
          ),
          AnswerOption(
            id: 'b',
            text: 'ArrayList',
            correct: true,
            explanation:
                'Correta. Implementa List, permite adicionar e remover '
                'elementos e mantém a ordem de inserção.',
          ),
          AnswerOption(
            id: 'c',
            text: 'HashMap',
            correct: false,
            explanation:
                'Incorreta. Armazena associações entre chaves e valores; não '
                'é uma implementação de List.',
          ),
          AnswerOption(
            id: 'd',
            text: 'TreeSet',
            correct: false,
            explanation:
                'Incorreta. Implementa Set e organiza os elementos segundo '
                'uma ordenação, não pela ordem de inserção.',
          ),
        ],
      ),

      // --- Collections — Intermediate (example from section 8.2) ---
      Question(
        id: 'seed-collections-intermediate-1',
        theme: 'Java Core',
        subtopic: 'Collections',
        statement: 'Considere o código abaixo. Qual é o resultado esperado?',
        codeSnippet: 'List<String> nomes = new ArrayList<>();\n'
            'nomes.add("Ana");\n'
            'nomes.add("Bruno");\n'
            'nomes.add("Ana");\n\n'
            'Set<String> unicos = new HashSet<>(nomes);\n\n'
            'System.out.println(unicos.size());',
        difficulty: Difficulty.intermediate,
        createdAt: now,
        options: const [
          AnswerOption(
            id: 'a',
            text: '2, porque o conjunto não mantém elementos duplicados.',
            correct: true,
            explanation:
                'Correta. A lista tem três elementos, mas dois são iguais. No '
                'HashSet, as duas ocorrências de "Ana" viram um único '
                'elemento, resultando em dois elementos distintos.',
          ),
          AnswerOption(
            id: 'b',
            text: '3, porque o conjunto preserva todos os elementos da lista.',
            correct: false,
            explanation:
                'Incorreta. O Set não mantém duplicados; a quantidade pode '
                'ser menor que a da lista original.',
          ),
          AnswerOption(
            id: 'c',
            text: '2, porque o conjunto mantém a ordem e remove apenas '
                'duplicatas consecutivas.',
            correct: false,
            explanation:
                'Incorreta. HashSet não garante ordem de inserção e elimina '
                'duplicatas sejam elas consecutivas ou não.',
          ),
          AnswerOption(
            id: 'd',
            text: 'O código não compila, pois não dá para criar HashSet de '
                'uma List.',
            correct: false,
            explanation:
                'Incorreta. O construtor de HashSet aceita uma coleção, '
                'incluindo List, com tipos compatíveis.',
          ),
        ],
      ),

      // --- Collections — Advanced (example from section 8.3) ---
      Question(
        id: 'seed-collections-advanced-1',
        theme: 'Java Core',
        subtopic: 'Collections',
        statement:
            'Uma aplicação recebe uma lista de códigos de produtos. Precisa '
            'remover duplicatas, preservar a ordem da primeira ocorrência de '
            'cada código e percorrer os resultados nessa mesma ordem. Qual '
            'alternativa atende melhor usando implementações padrão do Java?',
        difficulty: Difficulty.advanced,
        createdAt: now,
        options: const [
          AnswerOption(
            id: 'a',
            text:
                'Criar um HashSet a partir da lista, pois remove duplicatas e '
                'preserva a ordem de inserção.',
            correct: false,
            explanation:
                'Incorreta. HashSet elimina duplicatas, mas não garante a '
                'ordem de iteração.',
          ),
          AnswerOption(
            id: 'b',
            text:
                'Criar um TreeSet a partir da lista, pois remove duplicatas e '
                'mantém a ordem original de chegada.',
            correct: false,
            explanation:
                'Incorreta. TreeSet ordena os elementos pela ordenação '
                'natural ou por um comparador, não pela ordem de chegada.',
          ),
          AnswerOption(
            id: 'c',
            text:
                'Criar um LinkedHashSet a partir da lista e percorrê-lo, pois '
                'remove duplicatas e mantém a ordem de inserção.',
            correct: true,
            explanation:
                'Correta. LinkedHashSet elimina duplicados e mantém a ordem '
                'de inserção; a primeira ocorrência define a posição.',
          ),
          AnswerOption(
            id: 'd',
            text:
                'Ordenar a lista e convertê-la em ArrayList, pois a ordenação '
                'elimina duplicatas automaticamente.',
            correct: false,
            explanation:
                'Incorreta. Ordenar não remove duplicatas e ainda altera a '
                'ordem original de chegada.',
          ),
        ],
      ),

      // --- Exceções — Basic ---
      Question(
        id: 'seed-excecoes-basic-1',
        theme: 'Java Core',
        subtopic: 'Exceções',
        statement:
            'Em Java, qual bloco é executado independentemente de uma exceção '
            'ter sido lançada ou não, sendo útil para liberar recursos?',
        difficulty: Difficulty.basic,
        createdAt: now,
        options: const [
          AnswerOption(
            id: 'a',
            text: 'catch',
            correct: false,
            explanation:
                'Incorreta. O catch só executa quando uma exceção compatível '
                'é capturada.',
          ),
          AnswerOption(
            id: 'b',
            text: 'finally',
            correct: true,
            explanation:
                'Correta. O finally executa sempre, ocorrendo exceção ou não, '
                'sendo comum para fechar/liberar recursos.',
          ),
          AnswerOption(
            id: 'c',
            text: 'throw',
            correct: false,
            explanation:
                'Incorreta. throw é usado para lançar uma exceção, não para '
                'executar código ao final.',
          ),
          AnswerOption(
            id: 'd',
            text: 'try',
            correct: false,
            explanation:
                'Incorreta. O try delimita o código monitorado, mas não é o '
                'bloco garantido de finalização.',
          ),
        ],
      ),

      // --- Exceções — Intermediate ---
      Question(
        id: 'seed-excecoes-intermediate-1',
        theme: 'Java Core',
        subtopic: 'Exceções',
        statement:
            'Qual é a principal diferença entre exceções checadas (checked) e '
            'não checadas (unchecked) em Java?',
        difficulty: Difficulty.intermediate,
        createdAt: now,
        options: const [
          AnswerOption(
            id: 'a',
            text:
                'Exceções checadas devem ser tratadas ou declaradas; as não '
                'checadas (RuntimeException) não exigem isso.',
            correct: true,
            explanation:
                'Correta. O compilador obriga tratar/declarar exceções '
                'checadas; as unchecked estendem RuntimeException e não têm '
                'essa exigência.',
          ),
          AnswerOption(
            id: 'b',
            text:
                'Exceções não checadas não podem ser capturadas com try/catch.',
            correct: false,
            explanation:
                'Incorreta. Qualquer exceção pode ser capturada com try/catch, '
                'inclusive as unchecked.',
          ),
          AnswerOption(
            id: 'c',
            text: 'Exceções checadas sempre encerram a aplicação.',
            correct: false,
            explanation:
                'Incorreta. Se tratadas adequadamente, não encerram a '
                'aplicação.',
          ),
          AnswerOption(
            id: 'd',
            text:
                'Não há diferença prática; a distinção é apenas de nomenclatura.',
            correct: false,
            explanation:
                'Incorreta. A diferença afeta a obrigatoriedade de tratamento '
                'imposta pelo compilador.',
          ),
        ],
      ),

      // --- Lambdas e Streams — Basic ---
      Question(
        id: 'seed-streams-basic-1',
        theme: 'Java Core',
        subtopic: 'Lambdas e Streams',
        statement:
            'Em uma Stream do Java, qual operação é usada para transformar '
            'cada elemento em outro valor (por exemplo, aplicar uma função a '
            'cada item)?',
        difficulty: Difficulty.basic,
        createdAt: now,
        options: const [
          AnswerOption(
            id: 'a',
            text: 'filter',
            correct: false,
            explanation:
                'Incorreta. filter seleciona elementos conforme um predicado, '
                'não os transforma.',
          ),
          AnswerOption(
            id: 'b',
            text: 'map',
            correct: true,
            explanation:
                'Correta. map aplica uma função a cada elemento, produzindo um '
                'novo elemento correspondente.',
          ),
          AnswerOption(
            id: 'c',
            text: 'forEach',
            correct: false,
            explanation:
                'Incorreta. forEach apenas consome os elementos, sem produzir '
                'uma nova stream transformada.',
          ),
          AnswerOption(
            id: 'd',
            text: 'reduce',
            correct: false,
            explanation:
                'Incorreta. reduce combina os elementos em um único resultado, '
                'não transforma item a item.',
          ),
        ],
      ),

      // --- Lambdas e Streams — Intermediate ---
      Question(
        id: 'seed-streams-intermediate-1',
        theme: 'Java Core',
        subtopic: 'Lambdas e Streams',
        statement: 'Considere o código abaixo. Qual é a saída impressa?',
        codeSnippet: 'List<Integer> nums = List.of(1, 2, 3, 4, 5);\n'
            'int soma = nums.stream()\n'
            '    .filter(n -> n % 2 == 0)\n'
            '    .mapToInt(Integer::intValue)\n'
            '    .sum();\n'
            'System.out.println(soma);',
        difficulty: Difficulty.intermediate,
        createdAt: now,
        options: const [
          AnswerOption(
            id: 'a',
            text: '6',
            correct: true,
            explanation:
                'Correta. O filter mantém apenas os pares (2 e 4) e sum() '
                'resulta em 6.',
          ),
          AnswerOption(
            id: 'b',
            text: '15',
            correct: false,
            explanation:
                'Incorreta. 15 seria a soma de todos os elementos, mas o '
                'filter remove os ímpares.',
          ),
          AnswerOption(
            id: 'c',
            text: '9',
            correct: false,
            explanation:
                'Incorreta. 9 seria a soma dos ímpares (1+3+5), o oposto do '
                'filtro aplicado.',
          ),
          AnswerOption(
            id: 'd',
            text: '0',
            correct: false,
            explanation:
                'Incorreta. Há elementos pares na lista, então a soma não é 0.',
          ),
        ],
      ),
    ];
  }

  static String _slug(String s) => s
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'(^-|-$)'), '');
}
