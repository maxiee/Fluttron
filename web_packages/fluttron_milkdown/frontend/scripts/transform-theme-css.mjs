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
  const milkdownPattern = '.milkdown {';
  let currentIndex = sectionStart;
  let transformedCss = css;
  
  while (currentIndex < transformedCss.length) {
    const nextComment = transformedCss.indexOf('/* node_modules', currentIndex + 1);
    const nextMilkdown = transformedCss.indexOf(milkdownPattern, currentIndex);
    
    if (nextMilkdown === -1) break;
    if (nextComment !== -1 && nextMilkdown > nextComment) break;
    
    const beforeMilkdown = transformedCss.substring(
      Math.max(0, nextMilkdown - parentClass.length - 2),
      nextMilkdown
    );
    
    if (!beforeMilkdown.includes(parentClass)) {
      transformedCss = scopeMilkdownRule(transformedCss, nextMilkdown, parentClass);
    }
    
    currentIndex = transformedCss.indexOf('}', nextMilkdown) + 1;
  }
  
  return transformedCss;
}

function scopeMilkdownRule(css, ruleStart, parentClass) {
  const braceIndex = css.indexOf('{', ruleStart);
  if (braceIndex === -1) return css;
  
  let depth = 1;
  let closeIndex = braceIndex + 1;
  while (closeIndex < css.length && depth > 0) {
    if (css[closeIndex] === '{') depth++;
    else if (css[closeIndex] === '}') depth--;
    closeIndex++;
  }
  closeIndex--;
  
  const ruleContent = css.substring(braceIndex + 1, closeIndex);
  const beforeRule = css.substring(0, ruleStart);
  const afterRule = css.substring(closeIndex + 1);
  const match = beforeRule.match(/(\s*)$/);
  const whitespace = match ? match[1] : '';
  const newSelector = `.${parentClass} .milkdown`;
  const newRule = `${whitespace}${newSelector} {${ruleContent}}`;
  
  return beforeRule.slice(0, -whitespace.length) + newRule + afterRule;
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
  const scopedCount = (transformedCss.match(/milkdown-theme-\w+ \.milkdown/g) || []).length;
  
  console.log(`[transform-theme-css] Original .milkdown rules: ${originalCount}`);
  console.log(`[transform-theme-css] Scoped theme rules: ${scopedCount}`);
  
  const containerStyles = generateContainerStyles();
  transformedCss += '\n\n' + containerStyles;
  console.log('[transform-theme-css] Added container visual styles');
  
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

function generateContainerStyles() {
  return `/* Fluttron: Theme container visual styles */
.fluttron-milkdown {
  border-radius: 8px;
  transition: border-color 0.2s, background-color 0.2s;
}

/* Frame theme - neutral gray */
.milkdown-theme-frame {
  --crepe-color-background: #ffffff;
  --crepe-color-on-background: #000000;
  --crepe-color-surface: #f7f7f7;
  --crepe-color-primary: #333333;
  border: 2px solid #333333;
  background: #ffffff;
}

/* Frame dark theme */
.milkdown-theme-frame-dark {
  --crepe-color-background: #1a1a1a;
  --crepe-color-on-background: #e6e6e6;
  --crepe-color-surface: #121212;
  --crepe-color-primary: #b5b5b5;
  border: 2px solid #b5b5b5;
  background: #1a1a1a;
}

/* Nord theme - distinctive blue */
.milkdown-theme-nord {
  --crepe-color-background: #fdfcff;
  --crepe-color-on-background: #1b1c1d;
  --crepe-color-surface: #f8f9ff;
  --crepe-color-primary: #2e6db3;
  border: 2px solid #2e6db3;
  background: #f0f4fc;
}

/* Nord dark theme - blue accent */
.milkdown-theme-nord-dark {
  --crepe-color-background: #1b1c1d;
  --crepe-color-on-background: #f8f9ff;
  --crepe-color-surface: #111418;
  --crepe-color-primary: #88c0d0;
  border: 2px solid #88c0d0;
  background: #1b1c1d;
}
`;
}

if (process.argv[1]?.endsWith('transform-theme-css.mjs')) {
  transformThemeCss().catch((error) => {
    console.error('[transform-theme-css] Failed:', error);
    process.exit(1);
  });
}
