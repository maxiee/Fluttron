import {context, build} from 'esbuild';
import {constants} from 'node:fs';
import {access, mkdir, rm} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const uiRoot = path.resolve(__dirname, '..');
const sourceFile = path.join(uiRoot, 'frontend', 'src', 'main.js');
const outputFile = path.join(uiRoot, 'web', 'ext', 'main.js');
const outputCssFile = path.join(uiRoot, 'web', 'ext', 'main.css');

function relativePath(targetPath) {
  return path.relative(uiRoot, targetPath);
}

function createBuildOptions() {
  return {
    entryPoints: [sourceFile],
    outfile: outputFile,
    bundle: true,
    platform: 'browser',
    format: 'iife',
    target: ['es2020'],
    sourcemap: true,
    logLevel: 'info',
  };
}

async function ensureSourceFileExists() {
  try {
    await access(sourceFile, constants.F_OK);
  } catch (_) {
    throw new Error(`source file not found: ${relativePath(sourceFile)}`);
  }
}

async function buildFrontend() {
  await ensureSourceFileExists();
  await mkdir(path.dirname(outputFile), {recursive: true});
  await build(createBuildOptions());
  console.log(`[frontend] built ${relativePath(sourceFile)} -> ${relativePath(outputFile)}`);
}

async function cleanFrontend() {
  await rm(outputFile, {force: true});
  await rm(`${outputFile}.map`, {force: true});
  await rm(outputCssFile, {force: true});
  await rm(`${outputCssFile}.map`, {force: true});
  console.log(
    `[frontend] removed ${relativePath(outputFile)} and ${relativePath(outputCssFile)} (with sourcemaps)`,
  );
}

async function watchFrontend() {
  await ensureSourceFileExists();
  await mkdir(path.dirname(outputFile), {recursive: true});

  const watcher = await context(createBuildOptions());
  await watcher.watch();
  console.log(`[frontend] watching ${relativePath(sourceFile)}`);
  console.log(`[frontend] output ${relativePath(outputFile)}`);
}

async function main() {
  const args = new Set(process.argv.slice(2));
  if (args.has('--clean')) {
    await cleanFrontend();
    return;
  }
  if (args.has('--watch')) {
    await watchFrontend();
    return;
  }
  await buildFrontend();
}

main().catch((error) => {
  console.error('[frontend] build failed:', error);
  process.exitCode = 1;
});
