// خادم ملفات ثابتة لعرض نسخة الويب بعد البناء.
// تشغيل: node _serve.cjs  (من مجلد employee_portal_flutter)
const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = Number(process.env.PORT || 8080);
const ROOT = path.join(__dirname, 'build', 'web');

const TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.ttf': 'font/ttf',
  '.map': 'application/json; charset=utf-8',
  '.wasm': 'application/wasm',
};

if (!fs.existsSync(ROOT)) {
  console.error(`[serve] لم يُعثر على ${ROOT} — نفّذ أولاً: flutter build web --release`);
  process.exit(1);
}

const server = http.createServer((req, res) => {
  try {
    const url = decodeURIComponent((req.url || '/').split('?')[0]);
    let filePath = path.join(ROOT, path.normalize(url).replace(/^(\.\.[/\\])+/, ''));

    if (!filePath.startsWith(ROOT)) {
      res.writeHead(403).end('Forbidden');
      return;
    }

    if (!fs.existsSync(filePath) || fs.statSync(filePath).isDirectory()) {
      // دعم deep-linking في Flutter Web: أي مسار غير ملف يعود إلى index.html
      filePath = path.join(ROOT, 'index.html');
    }

    const body = fs.readFileSync(filePath);
    const type = TYPES[path.extname(filePath).toLowerCase()] || 'application/octet-stream';
    res.writeHead(200, {
      'Content-Type': type,
      'Content-Length': body.length,
      'Cache-Control': 'no-cache',
    });
    res.end(body);
  } catch (err) {
    res.writeHead(500, { 'Content-Type': 'text/plain; charset=utf-8' });
    res.end(`خطأ في الخادم: ${err.message}`);
  }
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`[serve] http://localhost:${PORT}  <-  ${ROOT}`);
});
