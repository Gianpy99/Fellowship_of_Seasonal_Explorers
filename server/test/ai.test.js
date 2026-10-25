import { test } from 'node:test';
import assert from 'node:assert/strict';
import { loadConfig } from '../config.js';
import { AiError, createAi, createOpenAiAi } from '../ai.js';

test('provider: explicit AI_PROVIDER wins, otherwise the available key decides', () => {
  assert.equal(loadConfig({}).ai.provider, 'none');
  assert.equal(loadConfig({ GEMINI_API_KEY: 'g' }).ai.provider, 'gemini');
  assert.equal(loadConfig({ OPENAI_API_KEY: 'o' }).ai.provider, 'openai');
  assert.equal(loadConfig({ GEMINI_API_KEY: 'g', OPENAI_API_KEY: 'o' }).ai.provider, 'gemini');
  assert.equal(loadConfig({ GEMINI_API_KEY: 'g', OPENAI_API_KEY: 'o', AI_PROVIDER: 'OpenAI' }).ai.provider, 'openai');
  assert.equal(createAi(loadConfig({}).ai), null);
  assert.equal(createAi(loadConfig({ AI_PROVIDER: 'openai' }).ai), null, 'no key means AI disabled');
  assert.equal(createAi(loadConfig({ OPENAI_API_KEY: 'o' }).ai).provider, 'openai');
  assert.equal(createAi(loadConfig({ GEMINI_API_KEY: 'g' }).ai).provider, 'gemini');
});

function fakeOpenAi(responses) {
  const calls = [];
  return {
    calls,
    images: {
      async generate(params) {
        calls.push(['image', params]);
        return { data: [{ b64_json: Buffer.from('img').toString('base64') }] };
      },
    },
    responses: {
      async create(params) {
        calls.push(['text', params]);
        const next = responses.shift();
        if (next instanceof Error) throw next;
        return { status: 'completed', output_text: next };
      },
    },
  };
}

test('openai: images, strict JSON schema and chat map to the right API calls', async () => {
  const client = fakeOpenAi(['{"questions":[]}', ' Ciao! ']);
  const ai = createOpenAiAi({ client, imageModel: 'img-model', textModel: 'text-model', imageQuality: 'low' });

  const img = await ai.generateImage('a lemon', { aspectRatio: '4:3' });
  assert.equal(img.toString(), 'img');
  assert.deepEqual(client.calls[0][1], {
    model: 'img-model', prompt: 'a lemon', size: '1536x1152', quality: 'low', output_format: 'webp', moderation: 'auto',
  });

  const schema = { type: 'object', properties: { q: { type: 'array', items: { type: 'object', properties: {} } } } };
  assert.deepEqual(await ai.generateJson('quiz please', schema, { model: 'big-model' }), { questions: [] });
  const jsonCall = client.calls[1][1];
  assert.equal(jsonCall.model, 'big-model');
  assert.equal(jsonCall.text.format.strict, true);
  assert.equal(jsonCall.text.format.schema.additionalProperties, false);
  assert.equal(jsonCall.text.format.schema.properties.q.items.additionalProperties, false);
  assert.equal(schema.additionalProperties, undefined, 'original schema untouched');

  const reply = await ai.chat('be nonna', [{ role: 'user', text: 'hi' }, { role: 'nonna', text: 'ciao' }]);
  assert.equal(reply, 'Ciao!');
  const chatCall = client.calls[2][1];
  assert.equal(chatCall.instructions, 'be nonna');
  assert.deepEqual(chatCall.input, [{ role: 'user', content: 'hi' }, { role: 'assistant', content: 'ciao' }]);
  assert.equal(chatCall.moderation.policy.input.mode, 'block');
});

test('openai: failures become AiError', async () => {
  const ai = createOpenAiAi({ client: fakeOpenAi([new Error('429 quota'), '']), imageModel: 'i', textModel: 't' });
  await assert.rejects(ai.chat('s', [{ role: 'user', text: 'x' }]), (e) => e instanceof AiError && /quota/.test(e.message));
  await assert.rejects(ai.generateJson('p', { type: 'object' }), AiError);
});
