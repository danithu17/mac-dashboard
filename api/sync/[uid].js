// In-memory cache for serverless execution
const syncStore = global._syncStore || (global._syncStore = {});

module.exports = (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  const { uid } = req.query;

  if (req.method === 'GET') {
    const data = syncStore[uid] || null;
    return res.status(200).json({ uid, data, success: true });
  }

  if (req.method === 'POST') {
    const payload = req.body || {};
    syncStore[uid] = payload.data || payload;
    return res.status(200).json({ success: true, message: 'Synced on Vercel' });
  }

  res.status(405).json({ error: 'Method not allowed' });
};
