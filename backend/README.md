# QUIZtion — Backend

Backend Node.js + Express que gera questões de múltipla escolha via API Gemini.
A chave do Gemini fica **exclusivamente aqui** (variável de ambiente), nunca no
aplicativo móvel.

## Pré-requisitos

- Node.js **>= 20** (recomendado 22).
- Uma chave da API Gemini (plano gratuito serve). Crie em
  https://aistudio.google.com/apikey

## Configuração

1. Instale as dependências:

   ```bash
   cd backend
   npm install
   ```

2. Crie o arquivo `.env` a partir do exemplo e preencha a chave:

   ```bash
   cp .env.example .env
   # edite .env e defina GEMINI_API_KEY=...
   ```

   Variáveis disponíveis (ver `.env.example`):
   - `GEMINI_API_KEY` — sua chave (obrigatória para gerar questões).
   - `GEMINI_MODEL` — modelo usado (padrão `gemini-3.8-flash`, com free tier
     de ~20 req/dia). Para mais requisições diárias, pode-se usar um modelo
     `flash-lite` (ex.: `gemini-3.5-flash-lite`), de menor qualidade.
   - `PORT` — porta HTTP local (padrão `3000`).
   - `MAX_QUESTIONS_PER_REQUEST` — limite de questões por requisição (padrão 10).

   > O `.env` está no `.gitignore` e **nunca** deve ser commitado.

## Rodando localmente

```bash
npm start        # inicia na porta configurada (padrão 3000)
# ou, com reinício automático ao salvar:
npm run dev
```

Verifique a saúde do servidor (não revela a chave, só informa se está
configurada):

```bash
curl http://localhost:3000/health
# {"status":"ok","geminiConfigured":true}
```

Teste a geração (precisa da chave e de internet):

```bash
curl -X POST http://localhost:3000/generate \
  -H "Content-Type: application/json" \
  -d '{"theme":"Biologia","subtopic":"Genética","difficulty":"basic","quantity":2}'
```

A resposta inclui `savedCount`, `failedCount` e `requested` (geração parcial é
reportada honestamente), além das questões em `saved`.

## Testes

```bash
npm test
```

Os testes usam um cliente Gemini **simulado** (mock), então **não consomem a
cota** da sua chave e não precisam de internet.

## Conectando o app

No app, informe a URL do backend em **Configurações**, por exemplo:

- Emulador Android apontando para o PC host: `http://10.0.2.2:3000`
- Celular físico na mesma rede Wi-Fi: `http://SEU_IP_LOCAL:3000`
  (descubra o IP com `ipconfig` no Windows ou `ip addr`/`ifconfig` no
  Linux/macOS)
- App rodando no navegador (Flutter web) no mesmo PC: `http://localhost:3000`

## Segurança (versão pessoal)

- A chave Gemini fica só no `.env` do servidor; nunca no app ou em logs.
- **Não há autenticação** no MVP: se você expuser este backend publicamente
  (ex.: via túnel ou deploy), qualquer pessoa com a URL pode chamá-lo e
  consumir sua cota do Gemini. Mantenha-o local ou protegido enquanto não houver
  autenticação. Há limites de quantidade por requisição e de tentativas de
  geração para reduzir abuso acidental.
