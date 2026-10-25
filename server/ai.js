import { GoogleGenAI, HarmBlockThreshold, HarmCategory } from '@google/genai';
import OpenAI from 'openai';

const KID_SAFETY = [
  HarmCategory.HARM_CATEGORY_HARASSMENT,
  HarmCategory.HARM_CATEGORY_HATE_SPEECH,
  HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT,
  HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT,
].map((category) => ({ category, threshold: HarmBlockThreshold.BLOCK_LOW_AND_ABOVE }));

/** Any failure talking to the AI provider (network, quota, safety block, bad output). */
export class AiError extends Error {
  name = 'AiError';
}

const wrap = (fn) => async (...args) => {
  try {
    return await fn(...args);
  } catch (err) {
    throw err instanceof AiError ? err : new AiError(err?.message ?? String(err));
  }
};

/**
 * Thin wrapper over the Gemini API. Keeps the key on the server and exposes
 * the three operations the app needs. Swap it for a fake in tests.
 */
export function createGeminiAi({ apiKey, imageModel, textModel }) {
  if (!apiKey) return null;
  const client = new GoogleGenAI({ apiKey });

  async function generateImage(prompt, { aspectRatio = '1:1' } = {}) {
    const response = await client.models.generateContent({
      model: imageModel,
      contents: prompt,
      config: {
        responseModalities: ['IMAGE'],
        imageConfig: { aspectRatio },
        safetySettings: KID_SAFETY,
      },
    });
    const part = response.candidates?.[0]?.content?.parts?.find((p) => p.inlineData?.data);
    if (!part) throw new AiError(`No image returned (${response.candidates?.[0]?.finishReason ?? response.promptFeedback?.blockReason ?? 'unknown reason'})`);
    return Buffer.from(part.inlineData.data, 'base64');
  }

  async function generateJson(prompt, schema, { model = textModel } = {}) {
    const response = await client.models.generateContent({
      model,
      contents: prompt,
      config: {
        responseMimeType: 'application/json',
        responseJsonSchema: schema,
        safetySettings: KID_SAFETY,
      },
    });
    if (!response.text) throw new AiError('Empty response');
    return JSON.parse(response.text);
  }

  async function chat(systemInstruction, messages) {
    const response = await client.models.generateContent({
      model: textModel,
      contents: messages.map((m) => ({ role: m.role === 'user' ? 'user' : 'model', parts: [{ text: m.text }] })),
      config: { systemInstruction, safetySettings: KID_SAFETY, temperature: 0.8 },
    });
    return response.text?.trim() || '';
  }

  return {
    provider: 'gemini',
    generateImage: wrap(generateImage),
    generateJson: wrap(generateJson),
    chat: wrap(chat),
    models: { imageModel, textModel },
  };
}

// OpenAI image sizes must be multiples of 16; 1536x1152 is exactly 4:3.
const OPENAI_SIZES = { '1:1': '1024x1024', '4:3': '1536x1152' };

// OpenAI strict structured outputs need additionalProperties: false on every object.
function strictSchema(schema) {
  if (Array.isArray(schema)) return schema.map(strictSchema);
  if (!schema || typeof schema !== 'object') return schema;
  const out = Object.fromEntries(Object.entries(schema).map(([k, v]) => [k, strictSchema(v)]));
  if (out.type === 'object') out.additionalProperties = false;
  return out;
}

/**
 * Same interface as createGeminiAi, backed by OpenAI (Images API + Responses API).
 * `client` can be injected in tests.
 */
export function createOpenAiAi({ apiKey, imageModel, textModel, imageQuality = 'medium', client }) {
  if (!apiKey && !client) return null;
  const openai = client ?? new OpenAI({ apiKey, maxRetries: 1, timeout: 180_000 });

  async function generateImage(prompt, { aspectRatio = '1:1' } = {}) {
    const result = await openai.images.generate({
      model: imageModel,
      prompt,
      size: OPENAI_SIZES[aspectRatio] ?? OPENAI_SIZES['1:1'],
      quality: imageQuality,
      output_format: 'webp',
      moderation: 'auto',
    });
    const b64 = result.data?.[0]?.b64_json;
    if (!b64) throw new AiError('No image returned');
    return Buffer.from(b64, 'base64');
  }

  async function generateJson(prompt, schema, { model = textModel } = {}) {
    const response = await openai.responses.create({
      model,
      input: prompt,
      reasoning: { effort: 'low' },
      text: { format: { type: 'json_schema', name: 'result', schema: strictSchema(schema), strict: true } },
    });
    if (!response.output_text) throw new AiError(`Empty response (${response.status ?? 'unknown status'})`);
    return JSON.parse(response.output_text);
  }

  async function chat(systemInstruction, messages) {
    const response = await openai.responses.create({
      model: textModel,
      instructions: systemInstruction,
      input: messages.map((m) => ({ role: m.role === 'user' ? 'user' : 'assistant', content: m.text })),
      reasoning: { effort: 'none' },
      max_output_tokens: 400,
      // Kids talk to this: block flagged input and output (surfaced as an AiError).
      moderation: { model: 'omni-moderation-latest', policy: { input: { mode: 'block' }, output: { mode: 'block' } } },
    });
    return response.output_text?.trim() || '';
  }

  return {
    provider: 'openai',
    generateImage: wrap(generateImage),
    generateJson: wrap(generateJson),
    chat: wrap(chat),
    models: { imageModel, textModel },
  };
}

/** Builds the configured provider (config.ai from loadConfig), or null when no key is set. */
export function createAi(aiConfig) {
  if (aiConfig.provider === 'openai') return createOpenAiAi(aiConfig.openai);
  if (aiConfig.provider === 'gemini') return createGeminiAi(aiConfig.gemini);
  return null;
}
