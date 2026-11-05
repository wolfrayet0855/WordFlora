// node check-copy.mjs  -> lints every guide string against CopySafety.banned (read from the Swift file) plus extras.
import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
const here = new URL('.', import.meta.url).pathname;
const C = createRequire(import.meta.url)(here + 'copy.js');
const swift = readFileSync(here + '../../WordFlora/Rules/CopySafety.swift', 'utf8');
const start = swift.indexOf('= [', swift.indexOf('static let banned'));
const banned = [...swift.slice(start, swift.indexOf(']', start)).matchAll(/"([^"]+)"/g)].map(m => m[1]);
if (banned.length < 20) { console.log('could not read CopySafety.banned'); process.exit(2); }
const extra = ['locked', 'lock', 'unlock', 'unlocks', 'lose', 'loses', 'plus', 'ad', 'ads', 'price', 'buy', 'subscription'];
const all = [...Object.values(C.ui), ...C.pages.flatMap(p => [p.title, ...p.lines, ...(p.linesQuiet || []), p.art]), ...C.artText];
let bad = 0;
for (const s of all) {
  const hits = [...banned, ...extra].filter(w => new RegExp('\\b' + w.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '\\b', 'i').test(s));
  if (hits.length) { bad++; console.log('BANNED', hits, '->', s); }
}
for (const p of C.pages) {
  const w = p.title.split(/\s+/).length;
  if (w > 5) { bad++; console.log('TITLE > 5 words:', p.title); }
  if (p.lines.length > 2) { bad++; console.log('More than 2 lines:', p.id); }
}
// rough grade check: average words per sentence and long words
const text = C.pages.flatMap(p => [p.title, ...p.lines]).join(' ');
const words = text.split(/\s+/).filter(Boolean);
const sentences = text.split(/[.!?]+/).filter(s => s.trim()).length;
const longW = words.filter(w => w.replace(/\W/g, '').length >= 9);
console.log(`banned list (${banned.length}) + extras checked over ${all.length} strings; problems: ${bad}`);
console.log(`words ${words.length}, sentences ~${sentences}, words/sentence ${(words.length / sentences).toFixed(1)}, 9+ letter words: ${longW.join(', ') || 'none'}`);
process.exit(bad ? 1 : 0);
