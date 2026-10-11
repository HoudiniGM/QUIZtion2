import '../domain/alternativa.dart';
import '../domain/dificuldade.dart';
import '../domain/questao.dart';
import '../domain/tipo_conteudo.dart';
import 'repositorio_questoes.dart';

/// Popula o banco local, na primeira execução, com temas e subtópicos
/// sugeridos (requisitos, seção 3) e um pequeno conjunto de questões de
/// exemplo — para que o fluxo de quiz funcione offline, sem IA.
///
/// Os exemplos NÃO limitam o uso do aplicativo: o usuário pode criar seus
/// próprios temas e subtópicos livremente.
class SemeadorDados {
  final RepositorioQuestoes _repo;

  SemeadorDados(this._repo);

  /// Executa o seed apenas se o banco ainda não tiver questões.
  Future<void> semearSeNecessario() async {
    final total = await _repo.contarQuestoes();
    if (total > 0) return;
    await semear();
  }

  Future<void> semear() async {
    final agora = DateTime(2026, 1, 1);

    // Estrutura de temas → subtópicos sugeridos.
    final estrutura = <String, List<String>>{
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

    for (final entrada in estrutura.entries) {
      final tema = entrada.key;
      await _repo.inserirTema(
        id: _slug(tema),
        nome: tema,
        criadoEm: agora,
      );
      for (final sub in entrada.value) {
        await _repo.inserirSubtopico(
          id: '${_slug(tema)}__${_slug(sub)}',
          temaId: _slug(tema),
          nome: sub,
          criadoEm: agora,
        );
      }
    }

    for (final q in _questoesExemplo(agora)) {
      await _repo.inserirQuestao(q);
    }
  }

  List<Questao> _questoesExemplo(DateTime agora) {
    return [
      // --- Java / Collections — Básico (ex. da seção 8.1) ---
      Questao(
        id: 'seed-collections-basico-1',
        tema: 'Java Core',
        subtopico: 'Collections',
        enunciado:
            'Qual implementação da interface List permite armazenar elementos '
            'em uma lista redimensionável e mantém a ordem de inserção?',
        dificuldade: Dificuldade.basico,
        criadaEm: agora,
        alternativas: const [
          Alternativa(
            id: 'a',
            texto: 'HashSet',
            correta: false,
            explicacao:
                'Incorreta. Implementa Set, não List, e não garante a ordem '
                'de inserção.',
          ),
          Alternativa(
            id: 'b',
            texto: 'ArrayList',
            correta: true,
            explicacao:
                'Correta. Implementa List, permite adicionar e remover '
                'elementos e mantém a ordem de inserção.',
          ),
          Alternativa(
            id: 'c',
            texto: 'HashMap',
            correta: false,
            explicacao:
                'Incorreta. Armazena associações entre chaves e valores; não '
                'é uma implementação de List.',
          ),
          Alternativa(
            id: 'd',
            texto: 'TreeSet',
            correta: false,
            explicacao:
                'Incorreta. Implementa Set e organiza os elementos segundo '
                'uma ordenação, não pela ordem de inserção.',
          ),
        ],
      ),

      // --- Java / Collections — Intermediário (ex. da seção 8.2) ---
      Questao(
        id: 'seed-collections-intermediario-1',
        tema: 'Java Core',
        subtopico: 'Collections',
        tipoConteudo: TipoConteudo.codigo,
        enunciado: 'Considere o código:\n\n'
            'List<String> nomes = new ArrayList<>();\n'
            'nomes.add("Ana");\n'
            'nomes.add("Bruno");\n'
            'nomes.add("Ana");\n\n'
            'Set<String> unicos = new HashSet<>(nomes);\n\n'
            'System.out.println(unicos.size());\n\n'
            'Qual é o resultado esperado?',
        dificuldade: Dificuldade.intermediario,
        criadaEm: agora,
        alternativas: const [
          Alternativa(
            id: 'a',
            texto: '2, porque o conjunto não mantém elementos duplicados.',
            correta: true,
            explicacao:
                'Correta. A lista tem três elementos, mas dois são iguais. No '
                'HashSet, as duas ocorrências de "Ana" viram um único '
                'elemento, resultando em dois elementos distintos.',
          ),
          Alternativa(
            id: 'b',
            texto:
                '3, porque o conjunto preserva todos os elementos da lista.',
            correta: false,
            explicacao:
                'Incorreta. O Set não mantém duplicados; a quantidade pode '
                'ser menor que a da lista original.',
          ),
          Alternativa(
            id: 'c',
            texto:
                '2, porque o conjunto mantém a ordem e remove apenas '
                'duplicatas consecutivas.',
            correta: false,
            explicacao:
                'Incorreta. HashSet não garante ordem de inserção e elimina '
                'duplicatas sejam elas consecutivas ou não.',
          ),
          Alternativa(
            id: 'd',
            texto:
                'O código não compila, pois não dá para criar HashSet de '
                'uma List.',
            correta: false,
            explicacao:
                'Incorreta. O construtor de HashSet aceita uma coleção, '
                'incluindo List, com tipos compatíveis.',
          ),
        ],
      ),

      // --- Java / Collections — Avançado (ex. da seção 8.3) ---
      Questao(
        id: 'seed-collections-avancado-1',
        tema: 'Java Core',
        subtopico: 'Collections',
        enunciado:
            'Uma aplicação recebe uma lista de códigos de produtos. Precisa '
            'remover duplicatas, preservar a ordem da primeira ocorrência de '
            'cada código e percorrer os resultados nessa mesma ordem. Qual '
            'alternativa atende melhor usando implementações padrão do Java?',
        dificuldade: Dificuldade.avancado,
        criadaEm: agora,
        alternativas: const [
          Alternativa(
            id: 'a',
            texto:
                'Criar um HashSet a partir da lista, pois remove duplicatas e '
                'preserva a ordem de inserção.',
            correta: false,
            explicacao:
                'Incorreta. HashSet elimina duplicatas, mas não garante a '
                'ordem de iteração.',
          ),
          Alternativa(
            id: 'b',
            texto:
                'Criar um TreeSet a partir da lista, pois remove duplicatas e '
                'mantém a ordem original de chegada.',
            correta: false,
            explicacao:
                'Incorreta. TreeSet ordena os elementos pela ordenação '
                'natural ou por um comparador, não pela ordem de chegada.',
          ),
          Alternativa(
            id: 'c',
            texto:
                'Criar um LinkedHashSet a partir da lista e percorrê-lo, pois '
                'remove duplicatas e mantém a ordem de inserção.',
            correta: true,
            explicacao:
                'Correta. LinkedHashSet elimina duplicados e mantém a ordem '
                'de inserção; a primeira ocorrência define a posição.',
          ),
          Alternativa(
            id: 'd',
            texto:
                'Ordenar a lista e convertê-la em ArrayList, pois a ordenação '
                'elimina duplicatas automaticamente.',
            correta: false,
            explicacao:
                'Incorreta. Ordenar não remove duplicatas e ainda altera a '
                'ordem original de chegada.',
          ),
        ],
      ),

      // --- Orientação a Objetos / Encapsulamento — Básico ---
      Questao(
        id: 'seed-oo-encapsulamento-basico-1',
        tema: 'Orientação a Objetos',
        subtopico: 'Encapsulamento',
        enunciado:
            'Qual é o principal objetivo do encapsulamento na orientação a '
            'objetos?',
        dificuldade: Dificuldade.basico,
        criadaEm: agora,
        alternativas: const [
          Alternativa(
            id: 'a',
            texto:
                'Proteger o estado interno de um objeto, controlando o acesso '
                'por meio de métodos.',
            correta: true,
            explicacao:
                'Correta. O encapsulamento restringe o acesso direto aos '
                'dados e expõe um comportamento controlado.',
          ),
          Alternativa(
            id: 'b',
            texto:
                'Permitir que uma classe herde atributos e métodos de outra.',
            correta: false,
            explicacao:
                'Incorreta. Isso descreve herança, não encapsulamento.',
          ),
          Alternativa(
            id: 'c',
            texto:
                'Permitir que um mesmo método se comporte de formas diferentes.',
            correta: false,
            explicacao: 'Incorreta. Isso descreve polimorfismo.',
          ),
          Alternativa(
            id: 'd',
            texto:
                'Dividir um sistema em camadas independentes de infraestrutura.',
            correta: false,
            explicacao:
                'Incorreta. Isso se refere a arquitetura em camadas, não a '
                'encapsulamento.',
          ),
        ],
      ),

      // --- Bancos de Dados / SQL — Básico ---
      Questao(
        id: 'seed-sql-basico-1',
        tema: 'Bancos de Dados',
        subtopico: 'SQL',
        enunciado:
            'Qual comando SQL é utilizado para recuperar dados de uma tabela?',
        dificuldade: Dificuldade.basico,
        criadaEm: agora,
        alternativas: const [
          Alternativa(
            id: 'a',
            texto: 'INSERT',
            correta: false,
            explicacao:
                'Incorreta. INSERT adiciona novas linhas a uma tabela.',
          ),
          Alternativa(
            id: 'b',
            texto: 'UPDATE',
            correta: false,
            explicacao: 'Incorreta. UPDATE altera linhas existentes.',
          ),
          Alternativa(
            id: 'c',
            texto: 'SELECT',
            correta: true,
            explicacao:
                'Correta. SELECT é o comando usado para consultar e recuperar '
                'dados de uma ou mais tabelas.',
          ),
          Alternativa(
            id: 'd',
            texto: 'DELETE',
            correta: false,
            explicacao: 'Incorreta. DELETE remove linhas de uma tabela.',
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
