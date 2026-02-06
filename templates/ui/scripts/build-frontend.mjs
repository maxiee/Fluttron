import {copyFile, mkdir, rm} from 'node:fs/promises';
import {watch} from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const uiRoot = path.resolve(__dirname, '..');
const sourceFile = path.join(uiRoot, 'frontend', 'src', 'main.js');
const outputFile = path.join(uiRoot, 'web', 'ext', 'main.js');

async function buildFrontend() {
  await mkdir(path.dirname(outputFile), {recursive: true});
  await copyFile(sourceFile, outputFile);
  console.log(`[frontend] copied ${relativePath(sourceFile)} -> ${relativePath(outputFile)}`);
}

async function cleanFrontend() {
  await rm(outputFile, {force: true});
  console.log(`[frontend] removed ${relativePath(outputFile)}`);
}

function relativePath(targetPath) {
  return path.relative(uiRoot, targetPath);
}

function watchFrontend() {
  let running = false;
  let queued = false;

  const run = async () => {
    if (running) {
      queued = true;
      return;
    }

    running = true;
    try {
      await buildFrontend();
    } catch (error) {
      console.error('[frontend] build failed:', error);
    } finally {
      running = false;
      if (queued) {
        queued = false;
        await run();
      }
    }
  };

  run();
  console.log(`[frontend] watching ${relativePath(sourceFile)}`);

  watch(sourceFile, (eventType, filename) => {
    const displayName = filename ?? 'main.js';
    console.log(`[frontend] change detected (${eventType}): ${displayName}`);
    run();
  });
}

const args = new Set(process.argv.slice(2));
if (args.has('--clean')) {
  await cleanFrontend();
} else if (args.has('--watch')) {
  watchFrontend();
} else {
  await buildFrontend();
}
