// Vercel runs this instead of `npm run build` (the "vercel-build" script).
// Production deploys apply pending migrations first; previews never do,
// because they share the production database.
const { execSync } = require('node:child_process');

const run = (cmd) => execSync(cmd, { stdio: 'inherit' });

if (process.env.VERCEL_ENV === 'production') {
  run('npx prisma migrate deploy');
} else {
  console.log(`Skipping migrations (VERCEL_ENV=${process.env.VERCEL_ENV ?? 'unset'})`);
}
run('npm run build');
