# QUIZtion

Aplicativo móvel de estudos por meio de questionários de múltipla escolha gerados por IA, em qualquer área do conhecimento. Organização em **Tema → Subtópico → Questões**, com quizzes offline e histórico de desempenho.

> MVP para uso pessoal, em um único dispositivo. Sem autenticação, contas ou sincronização entre dispositivos.

## Estrutura do repositório (monorepo)

```
QUIZtion2/
├── app/        # Aplicativo Flutter (Android + build Web para visualização)
├── backend/    # Backend Node.js + Express (implementado na Etapa 3)
├── docs/       # Decisões arquiteturais, limitações e setup
└── README.md
```

## Stack

| Camada            | Tecnologia                                      |
|-------------------|-------------------------------------------------|
| App móvel         | Flutter (Dart) — alvo Android, build Web de apoio |
| Estado            | provider                                         |
| Navegação         | go_router                                        |
| Armazenamento     | SQLite via drift                                 |
| Backend (Etapa 3) | Node.js + Express (deploy na Vercel)             |
| IA (Etapa 3)      | Google Gemini (chave somente no backend)         |

## Status do desenvolvimento

O projeto é construído de forma incremental (ver `docs/architecture.md`):

- **Etapa 1 — Base do app e quiz local (offline):** em andamento.
- Etapa 2 — Histórico e consistência.
- Etapa 3 — Backend e geração por IA.
- Etapa 4 — Acabamento e confiabilidade.

## Como rodar o app (Flutter)

**Pré-requisitos:** Flutter SDK **>= 3.27** (Dart >= 3.6) instalado e configurado no VS Code.

O repositório versiona o código-fonte (`lib/`, `test/`, `web/`, `pubspec.yaml`). As
pastas nativas de plataforma (`android/`, `ios/`, etc.) **não** são versionadas e
são geradas localmente pelo próprio Flutter. Na primeira vez:

```bash
cd app

# 1. Gera as pastas de plataforma (android/, web runtime, etc.) ao redor do lib/ já existente.
#    Não sobrescreve o seu código em lib/.
flutter create . --platforms=android,web

# 2. Baixa as dependências.
flutter pub get

# 3. Gera o código do drift (app_database.g.dart). Necessário antes de compilar/testar.
dart run build_runner build --delete-conflicting-outputs

# 4. Roda os testes de lógica (embaralhamento, validação, pontuação, quiz) e o smoke test.
flutter test

# 5. (Somente para a web) coloque sqlite3.wasm e drift_worker.js em web/.
#    Veja a seção "Observação para rodar no navegador (web)" abaixo.
#    Pule esta etapa se for rodar apenas no Android.

# 6. Executa o app.
flutter run -d chrome                 # no navegador (visualização rápida), ou
flutter run -d <seu-dispositivo>      # em um dispositivo/emulador Android
```

> Nas próximas vezes, basta `flutter pub get` + `dart run build_runner build` (quando
> o schema do banco mudar) e `flutter run`.

> **Nota:** o `flutter create .` gera um `test/widget_test.dart` padrão (teste de
> contador) que referencia uma classe `MyApp` inexistente neste projeto e faz
> `flutter test` falhar. O repositório já versiona o seu próprio
> `test/widget_test.dart` (um smoke test real do app). Se, após rodar
> `flutter create .`, o git acusar esse arquivo como modificado, descarte a
> versão gerada e mantenha a do repositório: `git checkout -- test/widget_test.dart`.

### Observação para rodar no navegador (web)

Para rodar na **web**, o drift precisa de dois arquivos auxiliares em
`app/web/`: `sqlite3.wasm` e `drift_worker.js`. Eles precisam ter a **mesma
versão** dos pacotes `drift` e `sqlite3` resolvidos no `pubspec.lock`, caso
contrário o app falha ao abrir o banco (tela branca / erro de MIME).

Baixe os arquivos compatíveis para `app/web/`:

- `drift_worker.js` — dos *releases* do drift:
  https://github.com/simolus3/drift/releases (tag `drift-<versão>`)
- `sqlite3.wasm` — dos *releases* do sqlite3.dart:
  https://github.com/simolus3/sqlite3.dart/releases (tag `sqlite3-<versão>`)

As versões a usar são as que aparecem no `app/pubspec.lock` (campos `version:`
dos pacotes `drift` e `sqlite3`).

> No **Android** nada disso é necessário — o SQLite nativo já é incluído via
> `sqlite3_flutter_libs`. Os testes (`flutter test`) usam SQLite nativo e
> também não dependem desses arquivos.

## Integração contínua (CI)

A cada push ou pull request na `main`, o GitHub Actions executa, para o app
Flutter (`.github/workflows/ci.yml`):

1. `flutter pub get`
2. `dart run build_runner build` (gera o código do drift)
3. `dart format --set-exit-if-changed` (checa formatação)
4. `flutter analyze` (erros de compilação e lint)
5. `flutter test` (testes de domínio, repositório e smoke test)

Build de APK/web e testes em emulador **não** fazem parte do CI nesta fase
(mantido enxuto); podem ser adicionados na Etapa 4.

## Segurança

A chave da API Gemini **nunca** é incluída no aplicativo móvel. Ela permanece exclusivamente no backend, em variável de ambiente. Ver `docs/architecture.md` para as limitações de segurança do MVP.
