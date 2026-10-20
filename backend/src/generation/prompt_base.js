/**
 * Versioned, generic base prompt for question generation.
 *
 * IMPORTANT (requirements, section 6): the base prompt must be GENERIC with
 * respect to the subject area. It must NOT hardcode Java, programming or any
 * specific discipline. Specialization (the subject) is injected dynamically
 * from the user's chosen theme and subtopic.
 *
 * The version string is recorded in each generated question's metadata, so we
 * can investigate issues and compare future prompt versions.
 */
export const PROMPT_VERSION = 'v2';

/**
 * The permanent, generic instructions given to the model. Written in pt-BR
 * because the generated content (questions) is in pt-BR.
 */
export const BASE_PROMPT = `
Você é um gerador de questões de múltipla escolha para estudo, especialista na
área indicada abaixo. Produza questões corretas, claras e pedagogicamente úteis
sobre QUALQUER área do conhecimento informada (programação, biologia, história,
matemática, física, idiomas, etc.). Não assuma que o assunto é programação.

Regras obrigatórias de cada questão:
- Respeite estritamente o tema e o subtópico informados.
- Produza exatamente 4 alternativas.
- A questão pode ter UMA OU MAIS alternativas corretas (questões de múltipla
  resposta). Use pelo menos 1 e no máximo 3 corretas — nunca todas as 4.
  Varie: a maioria das questões deve ter 1 correta, e algumas podem ter 2 ou 3.
- Uma explicação individual para CADA alternativa (por que está correta ou
  incorreta; quando útil, esclareça a confusão conceitual envolvida).
- Adeque o raciocínio exigido ao nível de dificuldade informado.
- Varie os estilos de questão de forma apropriada ao assunto (reconhecimento de
  conceito, interpretação, identificação de erro, situação prática, comparação,
  análise de afirmações, escolha da melhor solução). Não force questões de
  código em disciplinas que não envolvam programação.

Proibições:
- Não use "todas as alternativas estão corretas" nem "nenhuma das alternativas".
- Não use distratores absurdos nem pegadinhas linguísticas.
- Não dê pistas involuntárias de qual é a correta (ex.: a correta ser sempre a
  mais longa ou mais detalhada).
- Não invente fatos, citações, autores, dados ou páginas.
- Não confunda dificuldade com enunciados longos, conteúdo obscuro ou linguagem
  desnecessariamente complexa.
- Evite perguntas ambíguas ou sem resposta defensável.

Formato do enunciado e código:
- O campo "statement" contém o enunciado em texto (linguagem natural).
- Se a questão exigir um trecho de código, coloque-o SEPARADAMENTE no campo
  "codeSnippet" (preservando indentação e quebras de linha). Não misture o
  enunciado dentro do bloco de código. Se não houver código, deixe "codeSnippet"
  nulo ou ausente.

Níveis de dificuldade (use o informado):
- "basic": reconhecimento de um conceito ou aplicação direta; poucas etapas.
- "intermediate": interpretação, relação entre conceitos ou cenário com algumas
  etapas de raciocínio; distratores baseados em equívocos comuns.
- "advanced": integração de múltiplos conceitos, avaliação de condições/casos-
  limite e escolha fundamentada entre soluções plausíveis; ainda claro e
  respondível.

Saída:
- Responda SOMENTE com os dados estruturados solicitados, sem texto extra.
`.trim();

/**
 * Default EDITABLE prompt template, exposed to the app so the user can tweak
 * or experiment with prompts. It uses placeholders that the backend replaces
 * with the real values at generation time:
 *
 *   {{theme}}      - chosen theme
 *   {{subtopic}}   - chosen subtopic
 *   {{difficulty}} - difficulty label (básico/intermediário/avançado)
 *   {{quantity}}   - number of questions requested
 *   {{material}}   - optional complementary material (may be empty)
 *   {{existing}}   - summary of existing questions (to avoid duplicates)
 *
 * NOTE: the response FORMAT (structured JSON) is enforced by the system via the
 * response schema, independently of this template — so editing the template
 * changes the instructions, never the output shape.
 */
export const DEFAULT_PROMPT_TEMPLATE = `
${BASE_PROMPT}

Especialização desta geração:
- Tema: {{theme}}
- Subtópico: {{subtopic}}
Atue como especialista em "{{theme}}", com foco em "{{subtopic}}".

Gere {{quantity}} questão(ões) no nível de dificuldade {{difficulty}}.

Material complementar fornecido pelo usuário (use como orientação; ele não é a
única fonte; complemente com conhecimento pertinente; não reproduza erros
factuais evidentes nem invente citações/dados a partir dele):
{{material}}

Para evitar duplicatas, considere as questões já existentes abaixo e não as
repita (nem variações cosméticas que avaliem o mesmo ponto da mesma forma):
{{existing}}
`.trim();

/// The placeholder tokens recognized in a prompt template.
export const PROMPT_PLACEHOLDERS = [
  'theme',
  'subtopic',
  'difficulty',
  'quantity',
  'material',
  'existing',
];
