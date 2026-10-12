import '../domain/answer_option.dart';
import '../domain/difficulty.dart';
import '../domain/question.dart';
import 'question_repository.dart';

/// Populates the local database, on first run, with suggested themes and
/// subtopics (requirements, section 3) and a small set of example questions —
/// so the quiz flow works offline, without AI.
///
/// The examples do NOT limit the use of the app: the user can freely create
/// their own themes and subtopics.
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

    // Theme -> suggested subtopics structure. Content is user-facing (pt-BR).
    final structure = <String, List<String>>{
      'Java Core': [
        'Sintaxe, tipos e operadores',
        'Estruturas de controle',
        'Strings e arrays',
        'Collections',
        'Generics',
        'Exceções',
        'Lambdas e Streams',
        'Optional',
        'Enums e Records',
        'Concorrência (noções básicas)',
        'JVM e memória',
      ],
      'Orientação a Objetos': [
        'Classes e objetos',
        'Encapsulamento',
        'Herança',
        'Polimorfismo',
        'Abstração',
        'Interfaces e classes abstratas',
        'Composição',
        'Princípios SOLID',
      ],
      'Spring e Backend': [
        'Injeção de dependência',
        'Spring Boot',
        'Configuração e profiles',
        'Spring MVC',
        'APIs REST',
        'Validação',
        'Tratamento global de exceções',
        'Spring Data JPA',
        'Autenticação e autorização (noções básicas)',
      ],
      'Bancos de Dados': [
        'SQL',
        'SELECT, JOIN e agregações',
        'Chaves e relacionamentos',
        'Índices',
        'Transações',
        'Normalização',
        'JPA e Hibernate',
      ],
      'Testes': [
        'JUnit',
        'Mockito',
        'Testes unitários e de integração',
        'TDD',
      ],
      'Arquitetura e Ferramentas': [
        'Camadas de aplicações backend',
        'DTOs e entidades',
        'Princípios de arquitetura',
        'Git',
        'Maven e Gradle',
        'HTTP e códigos de status',
        'Estruturas de dados e algoritmos básicos',
      ],
    };

    for (final entry in structure.entries) {
      final theme = entry.key;
      await _repo.insertTheme(id: _slug(theme), name: theme, createdAt: now);
      for (final sub in entry.value) {
        await _repo.insertSubtopic(
          id: '${_slug(theme)}__${_slug(sub)}',
          themeId: _slug(theme),
          name: sub,
          createdAt: now,
        );
      }
    }

    for (final q in _exampleQuestions(now)) {
      await _repo.insertQuestion(q);
    }
  }

  List<Question> _exampleQuestions(DateTime now) {
    return [
      // --- Java / Collections — Basic (example from section 8.1) ---
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

      // --- Java / Collections — Intermediate (example from section 8.2) ---
      Question(
        id: 'seed-collections-intermediate-1',
        theme: 'Java Core',
        subtopic: 'Collections',
        statement:
            'Considere o código abaixo. Qual é o resultado esperado?',
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
            text:
                '3, porque o conjunto preserva todos os elementos da lista.',
            correct: false,
            explanation:
                'Incorreta. O Set não mantém duplicados; a quantidade pode '
                'ser menor que a da lista original.',
          ),
          AnswerOption(
            id: 'c',
            text:
                '2, porque o conjunto mantém a ordem e remove apenas '
                'duplicatas consecutivas.',
            correct: false,
            explanation:
                'Incorreta. HashSet não garante ordem de inserção e elimina '
                'duplicatas sejam elas consecutivas ou não.',
          ),
          AnswerOption(
            id: 'd',
            text:
                'O código não compila, pois não dá para criar HashSet de '
                'uma List.',
            correct: false,
            explanation:
                'Incorreta. O construtor de HashSet aceita uma coleção, '
                'incluindo List, com tipos compatíveis.',
          ),
        ],
      ),

      // --- Java / Collections — Advanced (example from section 8.3) ---
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

      // --- Object Orientation / Encapsulation — Basic ---
      Question(
        id: 'seed-oo-encapsulation-basic-1',
        theme: 'Orientação a Objetos',
        subtopic: 'Encapsulamento',
        statement:
            'Qual é o principal objetivo do encapsulamento na orientação a '
            'objetos?',
        difficulty: Difficulty.basic,
        createdAt: now,
        options: const [
          AnswerOption(
            id: 'a',
            text:
                'Proteger o estado interno de um objeto, controlando o acesso '
                'por meio de métodos.',
            correct: true,
            explanation:
                'Correta. O encapsulamento restringe o acesso direto aos '
                'dados e expõe um comportamento controlado.',
          ),
          AnswerOption(
            id: 'b',
            text:
                'Permitir que uma classe herde atributos e métodos de outra.',
            correct: false,
            explanation:
                'Incorreta. Isso descreve herança, não encapsulamento.',
          ),
          AnswerOption(
            id: 'c',
            text:
                'Permitir que um mesmo método se comporte de formas diferentes.',
            correct: false,
            explanation: 'Incorreta. Isso descreve polimorfismo.',
          ),
          AnswerOption(
            id: 'd',
            text:
                'Dividir um sistema em camadas independentes de infraestrutura.',
            correct: false,
            explanation:
                'Incorreta. Isso se refere a arquitetura em camadas, não a '
                'encapsulamento.',
          ),
        ],
      ),

      // --- Databases / SQL — Basic ---
      Question(
        id: 'seed-sql-basic-1',
        theme: 'Bancos de Dados',
        subtopic: 'SQL',
        statement:
            'Qual comando SQL é utilizado para recuperar dados de uma tabela?',
        difficulty: Difficulty.basic,
        createdAt: now,
        options: const [
          AnswerOption(
            id: 'a',
            text: 'INSERT',
            correct: false,
            explanation:
                'Incorreta. INSERT adiciona novas linhas a uma tabela.',
          ),
          AnswerOption(
            id: 'b',
            text: 'UPDATE',
            correct: false,
            explanation: 'Incorreta. UPDATE altera linhas existentes.',
          ),
          AnswerOption(
            id: 'c',
            text: 'SELECT',
            correct: true,
            explanation:
                'Correta. SELECT é o comando usado para consultar e recuperar '
                'dados de uma ou mais tabelas.',
          ),
          AnswerOption(
            id: 'd',
            text: 'DELETE',
            correct: false,
            explanation: 'Incorreta. DELETE remove linhas de uma tabela.',
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
