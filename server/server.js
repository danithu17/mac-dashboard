const http = require('http');
const fs = require('fs');
const path = require('path');
const os = require('os');

const PORT = process.env.PORT || 3000;
const DATA_DIR = path.join(__dirname, 'data');
const DB_FILE = path.join(DATA_DIR, 'sync-db.json');
const WEB_DIR = path.resolve(__dirname, '..', 'web');

// Ensure data directory exists
if (!fs.existsSync(DATA_DIR)) {
  fs.mkdirSync(DATA_DIR, { recursive: true });
}

// Ensure database file exists
if (!fs.existsSync(DB_FILE)) {
  fs.writeFileSync(DB_FILE, JSON.stringify({ users: [], syncData: {} }, null, 2), 'utf8');
}

function readDb() {
  try {
    const raw = fs.readFileSync(DB_FILE, 'utf8');
    return JSON.parse(raw);
  } catch (e) {
    return { users: [], syncData: {} };
  }
}

function writeDb(data) {
  try {
    fs.writeFileSync(DB_FILE, JSON.stringify(data, null, 2), 'utf8');
  } catch (e) {
    console.error('Failed to write database:', e);
  }
}

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.woff2': 'font/woff2',
  '.ttf': 'font/ttf'
};

// Security: Rate limiter (sliding 60-second window per IP)
const RATE_LIMIT_WINDOW_MS = 60 * 1000;
const MAX_REQUESTS_PER_WINDOW = 120;
const rateLimitMap = new Map();

function isRateLimited(ip) {
  const now = Date.now();
  let client = rateLimitMap.get(ip);
  if (!client || now - client.windowStart > RATE_LIMIT_WINDOW_MS) {
    client = { windowStart: now, count: 1 };
    rateLimitMap.set(ip, client);
    return false;
  }
  client.count++;
  return client.count > MAX_REQUESTS_PER_WINDOW;
}

// Security: UID Sanitizer to prevent directory traversal and prototype pollution
function isValidUid(uid) {
  if (!uid || typeof uid !== 'string') return false;
  if (uid === '__proto__' || uid === 'constructor' || uid === 'prototype') return false;
  return /^[a-zA-Z0-9_-]{1,64}$/.test(uid);
}

const MAX_PAYLOAD_BYTES = 2 * 1024 * 1024; // 2MB max payload

const server = http.createServer((req, res) => {
  const clientIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress || 'unknown';

  // Apply Rate Limiting
  if (isRateLimited(clientIp)) {
    res.writeHead(429, { 'Content-Type': 'application/json', 'Retry-After': '60' });
    res.end(JSON.stringify({ error: 'Too many requests. Please wait a moment.' }));
    return;
  }

  // Security Headers (Apple Security & OWASP Top 10 Hardened)
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'SAMEORIGIN');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
  res.setHeader('Permissions-Policy', 'camera=(), microphone=(), geolocation=()');
  res.setHeader('Content-Security-Policy', "default-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdn.tailwindcss.com https://fonts.googleapis.com https://fonts.gstatic.com; img-src 'self' data: https: blob:; font-src 'self' https: data:; connect-src 'self' http: https: ws: wss:;");

  // CORS Headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  const parsedUrl = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
  const pathname = decodeURIComponent(parsedUrl.pathname);

  // 1. Cost-Free Cross-Platform Sync REST API
  if (pathname.startsWith('/api/')) {
    if (pathname === '/api/health') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        status: 'ok',
        version: '1.0.0',
        security: 'hardened',
        serverTime: new Date().toISOString()
      }));
      return;
    }

    if (pathname === '/api/users') {
      if (req.method === 'GET') {
        const db = readDb();
        const safeUsers = (db.users || []).map(u => ({
          uid: u.uid,
          name: u.name,
          avatar: u.avatar || '👨‍💻',
          track: u.track || 'Personal',
          createdAt: u.createdAt
        }));
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(safeUsers));
        return;
      }

      if (req.method === 'POST') {
        let body = '';
        req.on('data', chunk => { body += chunk; });
        req.on('end', () => {
          try {
            const payload = JSON.parse(body);
            const user = payload.user || payload;
            if (user && isValidUid(user.uid)) {
              const db = readDb();
              if (!db.users) db.users = [];
              const idx = db.users.findIndex(u => u.uid === user.uid);
              const safeUser = {
                uid: user.uid,
                name: String(user.name || 'User').slice(0, 50),
                avatar: String(user.avatar || '👨‍💻').slice(0, 10),
                track: String(user.track || 'Personal').slice(0, 50),
                createdAt: user.createdAt || new Date().toISOString()
              };
              if (idx >= 0) db.users[idx] = Object.assign(db.users[idx], safeUser);
              else db.users.push(safeUser);
              writeDb(db);
              res.writeHead(200, { 'Content-Type': 'application/json' });
              res.end(JSON.stringify({ success: true, user: safeUser }));
              return;
            }
            res.writeHead(400, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ error: 'Invalid user payload' }));
          } catch (e) {
            res.writeHead(400, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ error: 'Invalid JSON payload' }));
          }
        });
        return;
      }
    }

    if (pathname.startsWith('/api/sync/') && req.method === 'GET') {
      const uid = pathname.replace('/api/sync/', '').trim();
      if (!isValidUid(uid)) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Invalid user identifier' }));
        return;
      }

      const db = readDb();
      const userData = (db.syncData && Object.prototype.hasOwnProperty.call(db.syncData, uid))
        ? db.syncData[uid]
        : null;

      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ uid, data: userData, success: true }));
      return;
    }

    if (pathname.startsWith('/api/sync/') && req.method === 'POST') {
      const uid = pathname.replace('/api/sync/', '').trim();
      if (!isValidUid(uid)) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Invalid user identifier' }));
        return;
      }

      let body = '';
      let receivedBytes = 0;

      req.on('data', chunk => {
        receivedBytes += chunk.length;
        if (receivedBytes > MAX_PAYLOAD_BYTES) {
          res.writeHead(413, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'Payload exceeds 2MB limit' }));
          req.destroy();
          return;
        }
        body += chunk;
      });

      req.on('end', () => {
        if (res.writableEnded) return;
        try {
          const payload = JSON.parse(body);
          const db = readDb();
          if (!db.syncData) db.syncData = {};
          db.syncData[uid] = payload.data || payload;

          if (payload.user && typeof payload.user === 'object') {
            const idx = db.users.findIndex(u => u.uid === uid);
            if (idx >= 0) db.users[idx] = payload.user;
            else db.users.push(payload.user);
          }

          writeDb(db);
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ success: true, message: 'Synced successfully' }));
        } catch (err) {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'Invalid JSON payload' }));
        }
      });
      return;
    }

    res.writeHead(404, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Endpoint not found' }));
    return;
  }

  // 2. Static File Serving with Path Traversal Protection
  const safeRelativePath = path.normalize(pathname).replace(/^(\.\.[\/\\])+/, '');
  let resolvedFilePath = path.resolve(WEB_DIR, safeRelativePath === path.sep ? 'index.html' : '.' + safeRelativePath);

  // Guard: Ensure file is inside WEB_DIR
  if (!resolvedFilePath.startsWith(WEB_DIR)) {
    res.writeHead(403, { 'Content-Type': 'text/plain; charset=utf-8' });
    res.end('Access Denied: Path traversal detected');
    return;
  }

  if (!fs.existsSync(resolvedFilePath) || fs.statSync(resolvedFilePath).isDirectory()) {
    resolvedFilePath = path.resolve(WEB_DIR, 'index.html');
  }

  const ext = path.extname(resolvedFilePath).toLowerCase();
  const contentType = MIME_TYPES[ext] || 'application/octet-stream';

  fs.readFile(resolvedFilePath, (err, content) => {
    if (err) {
      res.writeHead(500, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end('Server Error: ' + err.message);
      return;
    }
    res.writeHead(200, { 'Content-Type': contentType });
    res.end(content);
  });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`\n======================================================`);
  console.log(` PulseHabit Pro Server Live & Security Hardened!`);
  console.log(`======================================================`);
  console.log(`> Web Dashboard (Local):  http://localhost:${PORT}`);

  const interfaces = os.networkInterfaces();
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      if (iface.family === 'IPv4' && !iface.internal) {
        console.log(`> Mobile (Android Wi-Fi): http://${iface.address}:${PORT}`);
      }
    }
  }
  console.log(`> Cost-Free Sync API:    http://localhost:${PORT}/api/health`);
  console.log(`> Security: CSP, Rate Limiting & Path Traversal Guards Active`);
  console.log(`======================================================\n`);
});
