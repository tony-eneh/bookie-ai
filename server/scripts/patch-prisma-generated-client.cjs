const fs = require('node:fs');
const path = require('node:path');

const candidateClientPaths = [
  path.join(__dirname, '..', 'generated', 'prisma', 'client.ts'),
];
const importLine = "import { fileURLToPath } from 'node:url'";
const dirnameLine = "globalThis['__dirname'] = path.dirname(fileURLToPath(import.meta.url))";
const replacementLine = "globalThis['__dirname'] = __dirname";

const clientPath = candidateClientPaths.find((candidatePath) =>
  fs.existsSync(candidatePath),
);

if (!clientPath) {
  console.log(
    'Skipping Prisma generated client patch because no generated TypeScript client was found.',
  );
  process.exit(0);
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