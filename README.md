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

- **Etapa 1 — Base do app e quiz local (offline):** concluída e validada. ✅
- **Etapa 2 — Backend e geração por IA:** concluída e validada (backend em
  produção na Vercel, geração testada ponta a ponta). ✅
- Etapa 3 — Acabamento e confiabilidade (próxima).

> O histórico de tentativas foi **retirado do escopo** (ver `docs/architecture.md`,
> seção 9): o resultado é mostrado ao final de cada quiz, mas não é salvo.

## Gerar questões por IA (backend)

A geração de novas questões usa o backend (`backend/`), que fala com a API
Gemini. **Responder quizzes com questões já salvas funciona offline** — só a
geração precisa de internet e do backend no ar.

Configure o endereço do backend no app de uma destas formas:

- Em tempo de execução, na tela **Configurações** do app (recomendado para
  trocar sem recompilar).
- Em tempo de compilação, via `--dart-define`:
  ```bash
  flutter run --dart-define=BACKEND_URL=http://SEU_IP:3000
  ```

Para rodar o backend localmente, veja `backend/README` (ou `backend/.env.example`
para as variáveis, incluindo a chave Gemini). O deploy na Vercel é feito ao fim
da Etapa 2.

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
`app/web/`: `sqlite3.wasm` e `drift_worker.js`, nas versões compatíveis com os
pacotes `drift` e `sqlite3` do `pubspec.lock`. Sem eles o app falha ao abrir o
banco (tela branca / erro de MIME).

**Forma mais fácil** — rode o script que já baixa as versões certas:

```powershell
# Windows (PowerShell), a partir da pasta app:
./tool/fetch_web_assets.ps1
```
```bash
# Linux/macOS, a partir da pasta app:
./tool/fetch_web_assets.sh
```

**Manualmente** (se preferir), baixe para `app/web/`:

- `drift_worker.js` → https://github.com/simolus3/drift/releases/download/drift-2.31.0/drift_worker.js
- `sqlite3.wasm` → https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-2.9.4/sqlite3.wasm

> Os links acima são as versões que casam com o `pubspec.lock` atual
> (drift 2.31.0 / sqlite3 2.9.4). Se o `pubspec.lock` mudar, ajuste as versões
> nos scripts em `app/tool/`.
>
> No **Android** nada disso é necessário — o SQLite nativo já é incluído via
> `sqlite3_flutter_libs`. Os testes (`flutter test`) usam SQLite nativo e
> também não dependem desses arquivos.

## Gerar o APK (Android)

O build do APK é feito na sua máquina (precisa do Flutter + Android toolchain).

```bash
cd app
flutter create . --platforms=android,web   # 1ª vez (gera a pasta android/)
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# Build do APK já com a URL pública do backend (Vercel) embutida:
flutter build apk --release --dart-define=BACKEND_URL=https://SUA-URL.vercel.app
```

APK gerado em `app/build/app/outputs/flutter-apk/app-release.apk` — copie para o
celular e instale (permita "instalar de fontes desconhecidas").

Observações:
- No celular físico, o backend precisa ser a **URL pública (HTTPS) da Vercel**;
  `localhost`/`10.0.2.2` não funcionam fora do PC/emulador. A URL também pode ser
  definida em runtime na tela **Configurações** do app.
- Garanta a permissão de internet em
  `app/android/app/src/main/AndroidManifest.xml` (dentro de `<manifest>`):
  `<uses-permission android:name="android.permission.INTERNET"/>`.

### Ícone e nome do app

**Ícone do launcher:** o projeto já está configurado para gerar os ícones a
partir de `assets/logo-quiztion.png` (ver `flutter_launcher_icons` no
`pubspec.yaml`). Para aplicar:

```bash
cd app
flutter pub get
dart run flutter_launcher_icons
```

Isso cria os ícones em `android/` (nos vários tamanhos e no formato adaptativo,
com fundo navy da marca). Rode novamente sempre que trocar a imagem. Depois,
rebuild o APK.

**Nome do app** (abaixo do ícone): edite `android:label` em
`app/android/app/src/main/AndroidManifest.xml` (ex.: `android:label="QUIZtion"`).

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
