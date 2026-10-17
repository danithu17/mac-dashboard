// In-memory cache for serverless execution
const syncStore = global._syncStore || (global._syncStore = {});

function isValidUid(uid) {
  if (!uid || typeof uid !== 'string') return false;
  if (uid === '__proto__' || uid === 'constructor' || uid === 'prototype') return false;
  return /^[a-zA-Z0-9_-]{1,64}$/.test(uid);
}

module.exports = (req, res) => {
  // Security Headers
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'SAMEORIGIN');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');

  // CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  const { uid } = req.query;

  if (!isValidUid(uid)) {
    return res.status(400).json({ error: 'Invalid user identifier' });
  }

  if (req.method === 'GET') {
    const data = Object.prototype.hasOwnProperty.call(syncStore, uid) ? syncStore[uid] : null;
    return res.status(200).json({ uid, data, success: true });
  }

  if (req.method === 'POST') {
    const payload = req.body || {};
    syncStore[uid] = payload.data || payload;
    return res.status(200).json({ success: true, message: 'Synced on Vercel' });
  }

  res.status(405).json({ error: 'Method not allowed' });
};
