// Vercel Serverless Function: Cloud Users Registry Sync
const syncUsers = global._syncUsers || (global._syncUsers = [
  {
    uid: 'usr_default',
    name: 'Danithu',
    avatar: '👨‍💻',
    track: 'Software Engineering',
    createdAt: new Date().toISOString()
  }
]);

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

  if (req.method === 'GET') {
    const safeUsers = syncUsers.map(u => ({
      uid: u.uid,
      name: u.name,
      avatar: u.avatar || '👨‍💻',
      track: u.track || 'Personal',
      createdAt: u.createdAt
    }));
    return res.status(200).json(safeUsers);
  }

  if (req.method === 'POST') {
    const payload = req.body || {};
    const user = payload.user || payload;

    if (user && isValidUid(user.uid)) {
      const idx = syncUsers.findIndex(u => u.uid === user.uid);
      const safeEntry = {
        uid: user.uid,
        name: String(user.name || 'User').slice(0, 50),
        avatar: String(user.avatar || '👨‍💻').slice(0, 10),
        track: String(user.track || 'Personal').slice(0, 50),
        createdAt: user.createdAt || new Date().toISOString()
      };

      if (idx >= 0) {
        syncUsers[idx] = Object.assign(syncUsers[idx], safeEntry);
      } else {
        syncUsers.push(safeEntry);
      }

      return res.status(200).json({ success: true, users: syncUsers });
    }

    return res.status(400).json({ error: 'Invalid user payload' });
  }

  res.status(405).json({ error: 'Method not allowed' });
};
