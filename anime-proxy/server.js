import express from 'express';
import fetch from 'node-fetch';

const app = express();

// OPTIONAL: supaya bisa dipanggil dari Flutter Web (CORS)
app.use((req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', '*'); // izinkan semua origin
  res.setHeader('Access-Control-Allow-Methods', 'GET');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  next();
});

/*
  Route proxy:
  contoh panggilan: http://localhost:3000/proxy?target=https://desustream.com/embed/abc123
*/
app.get('/proxy', async (req, res) => {
  const target = req.query.target;

  if (!target) {
    return res.status(400).send('Missing ?target=');
  }

  try {
    // Ambil halaman sumber
    const upstream = await fetch(target.toString(), {
      headers: {
        // trick kecil: kirim UA mirip browser normal biar nggak ditolak
        'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.9',
        // kadang host player butuh Referer tertentu,
        // kalau perlu kamu bisa set manual di sini:
        // 'Referer': 'https://otakudesu.best/',
      },
    });

    const contentType = upstream.headers.get('content-type') || 'text/html';
    let body = await upstream.text();

    // 🌶 langkah penting:
    // Jangan teruskan header anti-embed dari upstream (kayak X-Frame-Options).
    // Kita juga bisa "sedikit reparasi" isi HTML kalau perlu.

    // Hapus CSP embed blocker di dalam <meta ... Content-Security-Policy ...>
    // (Optional, kalau player masih nge-set CSP-nya di dalam HTML)
    body = body.replace(
      /<meta[^>]+http-equiv=["']Content-Security-Policy["'][^>]*>/gi,
      ''
    );

    // Kirim balik ke browser kita sebagai HTML biasa
    res
      .status(200)
      .set({
        'Content-Type': contentType,
        // IZINKAN di-iframe dari mana saja
        'X-Frame-Options': 'ALLOWALL',
        // Jangan pasang CSP ketat di response proxy
        'Content-Security-Policy': "frame-ancestors *; default-src * 'unsafe-inline' 'unsafe-eval' data: blob:;",
        // CORS untuk jaga-jaga
        'Access-Control-Allow-Origin': '*',
      })
      .send(body);
  } catch (err) {
    console.error('Proxy error:', err);
    res.status(500).send('Proxy fetch failed.');
  }
});

// Jalankan server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`proxy running on http://localhost:${PORT}`);
});
