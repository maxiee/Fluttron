/**
 * Post-build CSS transformer for Milkdown themes.
 * 
 * Problem: @milkdown/crepe theme CSS files all define rules on `.milkdown` directly.
 * When all 4 themes are bundled, CSS cascade means the last theme always wins.
 * 
 * Solution: Transform each theme's `.milkdown` rules to be scoped under a unique
 * parent class like `.milkdown-theme-frame .milkdown { ... }`.
 * 
 * This module identifies theme sections in the bundled CSS by their source comments
 * and transforms the selectors accordingly.
 */

import { readFileSync, writeFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));

const CSS_FILE_PATH = resolve(__dirname, '../../web/ext/main.css');

// Theme mapping: source file pattern -> parent class
const THEME_MAPPINGS = [
  { sourcePattern: '/theme/frame/style.css', parentClass: 'milkdown-theme-frame' },
  { sourcePattern: '/theme/frame-dark/style.css', parentClass: 'milkdown-theme-frame-dark' },
  { sourcePattern: '/theme/nord/style.css', parentClass: 'milkdown-theme-nord' },
  { sourcePattern: '/theme/nord-dark/style.css', parentClass: 'milkdown-theme-nord-dark' },
];

function transformCssContent(css) {
  let result = css;
  const themePositions = [];
  
  for (const mapping of THEME_MAPPINGS) {
    let searchStart = 0;
    while (true) {
      const patternIndex = result.indexOf(mapping.sourcePattern, searchStart);
      if (patternIndex === -1) break;
      const afterPattern = result.substring(patternIndex, patternIndex + 200);
      if (afterPattern.includes('*/')) {
        themePositions.push({ index: patternIndex, parentClass: mapping.parentClass });
      }
      searchStart = patternIndex + mapping.sourcePattern.length;
    }
  }
  
  console.log(`[transform-theme-css] Found ${themePositions.length} theme sections`);
  themePositions.sort((a, b) => b.index - a.index);
  
  for (const pos of themePositions) {
    result = transformThemeSection(result, pos.index, pos.parentClass);
  }
  
  return result;
}

function transformThemeSection(css, sectionStart, parentClass) {
  const nextComment = css.indexOf('/* node_modules', sectionStart + 1);
  const sectionEnd = nextComment === -1 ? css.length : nextComment;
  const section = css.substring(sectionStart, sectionEnd);
  const scopedSection = section.replace(
    /(^|\n)([ \t]*)\.milkdown\s*\{/g,
    `$1$2.${parentClass} .milkdown, .${parentClass}.milkdown {`,
  );

  if (scopedSection === section) {
    return css;
  }

  return css.substring(0, sectionStart) + scopedSection + css.substring(sectionEnd);
}

export async function transformThemeCss(cssFilePath = CSS_FILE_PATH) {
  console.log('[transform-theme-css] Reading bundled CSS...');
  
  let css;
  try {
    css = readFileSync(cssFilePath, 'utf-8');
  } catch (error) {
    console.error(`[transform-theme-css] Error reading ${cssFilePath}:`, error.message);
    throw error;
  }
  
  console.log('[transform-theme-css] Transforming theme selectors...');
  
  let transformedCss = transformCssContent(css);
  
  const originalCount = (css.match(/\.milkdown\s*{/g) || []).length;
  const scopedCount = (
    transformedCss.match(/milkdown-theme-[\w-]+(?: \.milkdown|\.milkdown)/g) ||
    []
  ).length;
  
  console.log(`[transform-theme-css] Original .milkdown rules: ${originalCount}`);
  console.log(`[transform-theme-css] Scoped theme rules: ${scopedCount}`);
  
  console.log('[transform-theme-css] Writing transformed CSS...');
  
  try {
    writeFileSync(cssFilePath, transformedCss, 'utf-8');
  } catch (error) {
    console.error(`[transform-theme-css] Error writing ${cssFilePath}:`, error.message);
    throw error;
  }
  
  console.log('[transform-theme-css] Done!');
  
  return { originalCount, scopedCount };
}

if (process.argv[1]?.endsWith('transform-theme-css.mjs')) {
  transformThemeCss().catch((error) => {
    console.error('[transform-theme-css] Failed:', error);
    process.exit(1);
  });
}
