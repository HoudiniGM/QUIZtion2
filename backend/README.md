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
   - `GEMINI_MODEL` — modelo usado (padrão `gemini-3.5-flash-lite`, com free
     tier generoso de ~500 req/dia). Para maior qualidade (com free tier
     menor, ~20/dia), pode-se usar um modelo "flash" completo, ex.:
     `gemini-3.8-flash`.
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

Sugestão de tema/tópico a partir de texto livre (`POST /classify`):

```bash
curl -X POST http://localhost:3000/classify \
  -H "Content-Type: application/json" \
  -d '{"text":"quero treinar herança e polimorfismo","existingThemes":[]}'
# { "theme": "...", "topic": "...", "themeExists": false, "topicExists": false }
```

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

> **Atenção:** use `http://` (e NÃO `https://`) para o backend local — ele
> serve HTTP puro, sem certificado TLS. Um `https://` não conecta.

## Deploy na Vercel

O backend já está preparado para a Vercel (arquivos `api/index.js` e
`vercel.json`). O deploy roda o Express como função serverless; a URL pública
usa **HTTPS** automaticamente.

Passo a passo (painel da Vercel):

1. Em https://vercel.com, clique em **Add New… → Project** e importe o
   repositório `HoudiniGM/QUIZtion2`.
2. Em **Root Directory**, selecione **`backend`** (o projeto é um monorepo; a
   Vercel precisa apontar para a pasta do backend).
3. **Framework Preset:** "Other" (não é Next.js). Não é preciso build command.
4. Em **Environment Variables**, adicione:
   - `GEMINI_API_KEY` = sua chave (obrigatório).
   - `GEMINI_MODEL` = `gemini-3.5-flash-lite` (opcional; é o padrão).
   > Nunca coloque a chave no código nem no repositório — apenas aqui.
5. Clique em **Deploy**. Ao final, a Vercel dará uma URL como
   `https://quiztion-backend.vercel.app`.

Verifique:

```bash
curl https://SUA-URL.vercel.app/health
# {"status":"ok","geminiConfigured":true}
```

No app, informe essa URL (com **https://**) em **Configurações**. A partir
daí a geração funciona de qualquer rede, não só na sua Wi-Fi local.

> Após alterar variáveis de ambiente na Vercel, faça um **redeploy** para que
> passem a valer.

## Segurança (versão pessoal)

- A chave Gemini fica só no `.env` do servidor; nunca no app ou em logs.
- **Não há autenticação** no MVP: ao fazer deploy (ex.: na Vercel) o backend
  fica **público**, e qualquer pessoa com a URL pode chamá-lo e consumir sua
  cota do Gemini. Há limites de quantidade por requisição e de tentativas de
  geração para reduzir abuso acidental, mas eles não substituem autenticação.
  Mitigações possíveis no futuro: uma chave de acesso simples entre app e
  backend, ou restrição por origem. Enquanto isso, trate a URL como semi-
  secreta e acompanhe o uso da sua cota.
