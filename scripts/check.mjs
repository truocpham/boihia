// CI: kiểm tra nhanh app tĩnh. Chạy: node scripts/check.mjs
import { readFileSync, existsSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
const fail = m => { console.error('FAIL:', m); process.exitCode = 1 };

const html = readFileSync('index.html', 'utf8');
const inline = html.match(/<script>([\s\S]*?)<\/script>/)?.[1];
if (!inline) fail('index.html: không thấy script inline');
else try { new Function(inline) } catch (e) { fail('index.html script: ' + e.message) }

for (const f of ['sw.js', 'config.js']) {
  try { execFileSync(process.execPath, ['--check', f], { stdio: 'pipe' }) } catch (e) { fail(f + ': ' + e.stderr) }
}
try { JSON.parse(readFileSync('manifest.json', 'utf8')) } catch (e) { fail('manifest.json: ' + e.message) }
for (const f of ['icon.png', 'schema.sql']) if (!existsSync(f)) fail('thiếu ' + f);

// App không được ghi thẳng DB: mọi ghi phải qua rpc() có kiểm tra PIN (xem schema.sql).
if (/db\.from\([^)]*\)\.(insert|upsert|update|delete)\(/.test(inline ?? '')) fail('index.html: ghi trực tiếp vào bảng, phải dùng rpc');

if (!process.exitCode) console.log('OK');
