const MONTH_NAMES = {
  en: ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
  it: ['gennaio', 'febbraio', 'marzo', 'aprile', 'maggio', 'giugno', 'luglio', 'agosto', 'settembre', 'ottobre', 'novembre', 'dicembre'],
};

export const ART_STYLE =
  'Hand-painted watercolor storybook illustration for young children: soft pastel palette, warm golden light, ' +
  'gentle whimsical fantasy mood, rich natural details, cozy and friendly. No text, letters, logos or watermarks in the image.';

export const CHARACTERS = {
  Lina: 'Lina, a curious 8-year-old Calabrian girl with dark curly hair, a yellow dress and a red neckerchief',
  Taro: 'Taro, a small friendly travelling sprite from southern England with pointed ears, a green hooded cloak and a leather satchel',
  'Nonna Rosa': 'Nonna Rosa, a kind elderly Italian grandmother with a silver bun, round glasses and a flowery apron',
  Piuma: 'Piuma, a little talking robin with a bright orange-red breast',
};

const REGION_SETTING = {
  calabria: 'in sunny Calabria, southern Italy: olive groves, citrus trees, stone villages and the sparkling Mediterranean sea',
  england: 'in the gentle countryside of southern England: hedgerows, cottage gardens, misty meadows and old stone walls',
};

export const monthsText = (months, lang = 'en') => months.map((m) => MONTH_NAMES[lang][m - 1]).join(', ');

export function iconPrompt(product) {
  return [
    ART_STYLE,
    `A single ${product.name.en} (Italian: ${product.name.it}) as a charming, appealing hero object, centered,`,
    'shown whole with a few leaves or a little sprig, on a plain soft cream background with a faint watercolor halo.',
    'Simple clean composition that reads well as a small app icon. Square format.',
  ].join(' ');
}

export function storyPrompt(product, story) {
  const text = story.text.en || story.text.it;
  const cast = Object.entries(CHARACTERS)
    .filter(([name]) => text.includes(name) || (story.text.it ?? '').includes(name))
    .map(([, description]) => description);
  return [
    ART_STYLE,
    `Illustrate this moment from a children's story: "${text}"`,
    `Setting: ${REGION_SETTING[story.region] ?? REGION_SETTING.calabria}.`,
    `The ${product.name.en} must be clearly visible and recognisable as a key element of the scene.`,
    cast.length ? `Characters (keep these exact looks): ${cast.join('; ')}.` : 'No people need to appear unless the story mentions them.',
    'Wide storybook composition, landscape format.',
  ].join(' ');
}

const LANG_NAME = { it: 'Italian', en: 'English' };

function productFacts(product, lang) {
  return [
    `Name: ${product.name[lang]} (${lang === 'it' ? product.name.en : product.name.it})`,
    `Category: ${product.category}`,
    `Harvested in: ${monthsText(product.harvestMonths, lang) || 'n/a'}`,
    `Found in shops in: ${product.yearRound ? 'all year' : monthsText(product.shelfMonths, lang)}`,
    `Typical place: ${product.town}, ${product.region === 'england' ? 'southern England' : 'Calabria'}`,
    `Notes: ${product.notes[lang]}`,
    `For kids: ${product.kidNote[lang]}`,
    product.funFact?.[lang] ? `Fun fact: ${product.funFact[lang]}` : '',
  ]
    .filter(Boolean)
    .join('\n');
}

export const QUIZ_SCHEMA = {
  type: 'object',
  properties: {
    questions: {
      type: 'array',
      minItems: 4,
      maxItems: 4,
      items: {
        type: 'object',
        properties: {
          question: { type: 'string' },
          options: { type: 'array', items: { type: 'string' }, minItems: 3, maxItems: 3 },
          answer: { type: 'integer', minimum: 0, maximum: 2 },
          explanation: { type: 'string' },
        },
        required: ['question', 'options', 'answer', 'explanation'],
      },
    },
  },
  required: ['questions'],
};

export function quizPrompt(product, lang) {
  return [
    `Write a fun multiple-choice quiz in ${LANG_NAME[lang]} for children aged 5 to 10 about this seasonal food.`,
    'Exactly 4 questions, each with 3 short options and exactly one correct answer (answer = index 0-2).',
    'Mix the position of the correct answer. Questions should cover: when it is in season, what it looks/tastes like or how it grows,',
    'where it comes from, and one simple way families use it. Use only facts that are common knowledge or given below.',
    'Keep every sentence short, cheerful and easy to read aloud. The explanation is one encouraging sentence.',
    '',
    productFacts(product, lang),
  ].join('\n');
}

export function nonnaSystemPrompt(product, lang) {
  return [
    `You are Nonna Rosa, a warm, wise grandmother from Calabria in a children's educational app. Always reply in ${LANG_NAME[lang]}.`,
    `You are chatting with a child (age 5-12) about ${product.name[lang]}. Keep answers to 1-3 short, simple sentences,`,
    'with gentle humour and the occasional emoji. You may mention your friends Lina, Taro the sprite and Piuma the robin.',
    'Talk only about food, plants, animals, nature, seasons, cooking with a grown-up, and Calabria or England.',
    'If asked about anything else, or anything scary, unsafe or personal, kindly steer back to the topic.',
    'Never ask for or repeat personal information (names of schools, addresses, phone numbers, photos).',
    'Remind the child to ask a grown-up before using knives, the stove or picking wild plants. If unsure of a fact, say so.',
    '',
    'Facts you know about this product:',
    productFacts(product, lang),
  ].join('\n');
}

export const CONTENT_FIX_SCHEMA = {
  type: 'object',
  properties: {
    emoji: { type: 'string', description: 'One single emoji that best represents this product' },
    name: { type: 'object', properties: { it: { type: 'string' }, en: { type: 'string' } }, required: ['it', 'en'] },
    notes: { type: 'object', properties: { it: { type: 'string' }, en: { type: 'string' } }, required: ['it', 'en'] },
    kidNote: { type: 'object', properties: { it: { type: 'string' }, en: { type: 'string' } }, required: ['it', 'en'] },
    funFact: { type: 'object', properties: { it: { type: 'string' }, en: { type: 'string' } }, required: ['it', 'en'] },
    stories: {
      type: 'array',
      items: {
        type: 'object',
        properties: { id: { type: 'string' }, it: { type: 'string' }, en: { type: 'string' } },
        required: ['id', 'it', 'en'],
      },
    },
  },
  required: ['emoji', 'name', 'notes', 'kidNote', 'funFact', 'stories'],
};

export function contentFixPrompt(product) {
  const payload = {
    name: product.name,
    category: product.category,
    harvestMonths: product.harvestMonths,
    town: product.town,
    region: product.region,
    notes: product.notes,
    kidNote: product.kidNote,
    stories: product.stories.map((s) => ({ id: s.id, region: s.region, it: s.text.it, en: s.text.en })),
  };
  return [
    'You are a bilingual (Italian/English) children\'s book editor. Clean up this seasonal food entry for a kids\' app (ages 5-12).',
    'Rules:',
    '- Every "it" field must be natural, correct Italian; every "en" field natural British English. Translate any text in the wrong language.',
    '- Fix grammar and gender agreement (e.g. "il bergamotto", not "una piccola bergamotto"). Replace vague words like "the product" with the real name.',
    '- Each story pair must tell the same story in both languages. Keep the meaning, the cosy fairy-tale tone, the characters',
    '  (Lina, Taro the sprite, Nonna Rosa, Piuma the robin) and the region. Keep each story 2-4 short sentences.',
    '- Keep facts accurate; do not invent uncertain facts. notes = 1 sentence, kidNote = 1 short sentence for a child.',
    '- funFact: one true, surprising, child-friendly fact about this food.',
    '- Return every story id exactly once, unchanged.',
    '',
    JSON.stringify(payload, null, 1),
  ].join('\n');
}
