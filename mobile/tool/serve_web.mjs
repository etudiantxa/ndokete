import { createServer } from 'node:http';
import { createReadStream, existsSync, statSync } from 'node:fs';
import { extname, join, normalize } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = normalize(join(fileURLToPath(new URL('.', import.meta.url)), '..', 'build', 'web'));
const port = Number(process.env.PORT || 5000);

const contentTypes = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.ico': 'image/x-icon',
  '.wasm': 'application/wasm',
};

const server = createServer((request, response) => {
  const requestPath = decodeURIComponent((request.url || '/').split('?')[0]);
  const candidate = normalize(join(root, requestPath));
  const safePath = candidate.startsWith(root) ? candidate : root;
  const filePath = existsSync(safePath) && statSync(safePath).isFile()
    ? safePath
    : join(root, 'index.html');

  response.setHeader('Cache-Control', 'no-cache');
  response.setHeader('Content-Type', contentTypes[extname(filePath)] || 'application/octet-stream');
  createReadStream(filePath)
    .on('error', () => {
      response.statusCode = 500;
      response.end('Unable to serve NDOKETE Web');
    })
    .pipe(response);
});

server.listen(port, '0.0.0.0', () => {
  console.log(`NDOKETE Flutter Web listening on 0.0.0.0:${port}`);
});