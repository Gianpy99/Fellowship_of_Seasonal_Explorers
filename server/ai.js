import { GoogleGenAI, HarmBlockThreshold, HarmCategory } from '@google/genai';

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
    generateImage: wrap(generateImage),
    generateJson: wrap(generateJson),
    chat: wrap(chat),
    models: { imageModel, textModel },
  };
}
