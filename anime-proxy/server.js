import express from 'express';
import fetch from 'node-fetch';

const app = express();

// Izinkan semua origin
app.use((req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  next();
});

/**
 * Proxy endpoint universal:
 * Bisa buat gambar (.jpg, .png, dll), video, JSON, HTML, dll.
 *
 * Contoh:
 *   http://localhost:3000/proxy?target=https://www.sankavollerei.com/anime/home
 *   http://localhost:3000/proxy?target=https://www.sankavollerei.com/images/poster.jpg
 */
app.get('/proxy', async (req, res) => {
  const target = req.query.target;
  if (!target) {
    return res.status(400).send('Missing ?target=');
  }

  try {
    const response = await fetch(target.toString(), {
      headers: {
        'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122 Safari/537.36',
        'Accept': '*/*',
      },
    });

    // Ambil content-type dari response asli
    const contentType = response.headers.get('content-type') || 'application/octet-stream';
    const buffer = await response.arrayBuffer();

    res
      .status(response.status)
      .set({
        'Content-Type': contentType,
        'Access-Control-Allow-Origin': '*',
        'Cache-Control': 'public, max-age=3600',
        // IZINKAN embed (buat video/iframe)
        'X-Frame-Options': 'ALLOWALL',
        'Content-Security-Policy':
          "frame-ancestors *; default-src * 'unsafe-inline' 'unsafe-eval' data: blob:;",
      })
      .send(Buffer.from(buffer));
  } catch (err) {
    console.error('Proxy error:', err);
    res.status(500).send('Proxy fetch failed.');
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Proxy server running at http://localhost:${PORT}`);
});
