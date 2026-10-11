# Decisões Arquiteturais — QUIZtion

Documento vivo com as principais decisões de arquitetura do MVP e suas justificativas. Atualizado a cada etapa.

## 1. Visão geral

QUIZtion é um app de estudos por quizzes de múltipla escolha gerados por IA, em qualquer área do conhecimento, organizados em **Tema → Subtópico → Questões**. O MVP é para uso pessoal, em um único dispositivo Android, e deve funcionar **offline** para consultar e responder questões já salvas. A geração de novas questões exige internet e passa por um backend.

## 2. Arquitetura de alto nível

```
┌─────────────────────────┐        HTTPS         ┌──────────────────────────┐
│   App Flutter (Android)  │  ───────────────────▶│  Backend Node.js/Express │
│                          │   gerar questões     │   (deploy na Vercel)     │
│  - UI (Compose/Widgets)  │ ◀─────────────────── │                          │
│  - Estado (provider)     │   questões validadas │  - Prompt-base versionado│
│  - SQLite local (drift)  │                      │  - Chamada ao Gemini     │
│  - Quiz/histórico OFFLINE│                      │  - Validação de questões │
└─────────────────────────┘                      │  - Chave Gemini (.env)   │
                                                   └──────────────────────────┘
                                                              │
                                                              ▼
                                                       Google Gemini API
```

- **O app nunca contém a chave Gemini.** O backend é separado e remoto justamente para manter a chave fora do dispositivo (requisitos 2, 17, 20). Um backend embutido no app distribuiria a chave junto — por isso foi descartado.
- **Tudo que não exige IA funciona offline:** banco de questões, execução de quizzes, resultados e histórico vivem no SQLite local.

## 3. Escolhas tecnológicas

### App: Flutter (Dart)
- **Por quê:** é a tecnologia que o desenvolvedor domina e consegue testar no próprio ambiente (VS Code), sem depender de Android Studio. Atende integralmente o MVP (SQLite local, telas, offline) e mantém aberta a evolução para iOS/Web.
- **Build Web** é usado como apoio de visualização (abrir o fluxo no navegador); o alvo oficial continua Android.

### Estado: provider
- Simples e suficiente para o escopo do MVP; baixa curva de aprendizado e fácil de testar.

### Navegação: go_router
- Navegação declarativa entre as telas, adequada ao número de rotas do MVP.

### Armazenamento local: SQLite via drift
- **Por quê drift:** SQLite tipado, com queries verificadas em tempo de compilação, migrações versionadas e excelente testabilidade (importante para os critérios de aceitação da seção 18). Preserva integridade referencial entre questão → alternativas → explicações, requisito central para que o embaralhamento não quebre associações.

### Backend (Etapa 3): Node.js + Express na Vercel
- **Por quê:** simples, baixo custo (free tier), URL fixa acessível de qualquer rede. A chave Gemini fica em variável de ambiente no servidor.
- **Risco documentado:** no MVP não há autenticação. Um backend público sem proteção pode ser chamado por terceiros, consumindo a cota do Gemini. Mitigações previstas: limite de questões por requisição, limite de tentativas de correção/regeração e, futuramente, uma chave de acesso simples entre app e backend. Ver seção de Limitações.

## 4. Modelo de dados (local)

Entidades principais (detalhadas no schema drift em `app/lib/data/`):

- **temas** — id, nome, data de criação.
- **subtopicos** — id, tema_id (FK), nome, data de criação.
- **questoes** — id, subtopico_id (FK), enunciado, tipo de conteúdo (texto/código), dificuldade (basico/intermediario/avancado), tags (opcional), data de criação, versão do prompt (nullable), metadados de geração (nullable).
- **alternativas** — id, questao_id (FK), texto, explicação individual, flag `correta`, ordem estável. Cada alternativa mantém sua explicação e identidade mesmo após embaralhamento.
- **tentativas** — id, data, dados de desempenho (preenchido a partir da Etapa 2).
- **respostas_tentativa** — id, tentativa_id (FK), questao_id, alternativa escolhida, correta/incorreta.

O modelo é extensível: campos de imagem/diagrama **não** são implementados agora, mas a estrutura permite adicioná-los no futuro sem reescrita (requisitos 10, 11, 21).

## 5. Regras de negócio centrais

- **Geração exige tema + subtópico** (validado no app e, na Etapa 3, também no backend).
- **Cada questão:** exatamente 4 alternativas, exatamente 1 correta, 1 explicação por alternativa.
- **Embaralhamento** automático de questões e de alternativas, preservando a associação alternativa ↔ correta ↔ explicação.
- **Resposta confirmada no quiz é definitiva** (não editável depois).
- **Geração parcial é reportada com honestidade** (quantas salvas, quantas falharam) — Etapa 3.

## 6. Limitações conhecidas do MVP

- Uso pessoal, um único dispositivo; sem contas, sem sincronização.
- Backend sem autenticação (risco documentado acima).
- Material complementar aceita apenas texto colado (sem PDF) na primeira versão.
- Sem imagens/diagramas; sem execução de código; apenas múltipla escolha.
- App nativo não compilável no ambiente de desenvolvimento assistido (sem Flutter SDK lá); o backend é testável nesse ambiente. Testes do app rodam no ambiente do desenvolvedor.

## 7. Histórico de decisões

- Stack do app migrada de Kotlin nativo → **Flutter**, pois o desenvolvedor não possui/não pode instalar Android Studio e já domina Flutter no VS Code. Flutter atende os requisitos e viabiliza a validação pelo próprio desenvolvedor.
