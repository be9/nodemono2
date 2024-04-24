import fastify from 'fastify';
import { getPuppeteerVersion } from '@nodemono2/lib1';
import { getSomeInfo } from '@nodemono2/lib2';
import { Date as ProtoDate } from '@nodemono2/proto/build/google/type/date';

const server = fastify({ logger: true });

server.get('/', async (request, reply) => {
  const today = ProtoDate.fromJsDate(new Date());

  // this starts up puppeteer every time but who cares
  const lib1 = await (getPuppeteerVersion().catch((e) => `Error: ${e}`));

  return {
    lib1,
    lib2: await getSomeInfo(),
    today: ProtoDate.toJson(today),
  };
});

server.get('/about', async (request, reply) => {
  return { about: 'We are cool' };
});

const start = async () => {
  try {
    await server.listen({ host: '0.0.0.0', port: 3000 });
    console.log(`Server listening on port 3000`);
  } catch (err) {
    server.log.error(err);
    process.exit(1);
  }
};

start();
