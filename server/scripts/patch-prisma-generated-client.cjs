const fs = require('node:fs');
const path = require('node:path');

const clientPath = path.join(__dirname, '..', 'generated', 'prisma', 'client.ts');
const importLine = "import { fileURLToPath } from 'node:url'";
const dirnameLine = "globalThis['__dirname'] = path.dirname(fileURLToPath(import.meta.url))";
const replacementLine = "globalThis['__dirname'] = __dirname";

if (!fs.existsSync(clientPath)) {
  console.error(`Prisma client source not found at ${clientPath}`);
  process.exit(1);
}

const content = fs.readFileSync(clientPath, 'utf8');

if (content.includes(replacementLine) && !content.includes(dirnameLine)) {
  process.exit(0);
}

if (!content.includes(dirnameLine)) {
  console.error('Expected Prisma generated client format not found.');
  process.exit(1);
}

const updatedContent = content
  .replace(`${importLine}\n`, '')
  .replace(dirnameLine, replacementLine);

fs.writeFileSync(clientPath, updatedContent);