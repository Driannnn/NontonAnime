# 🚨 MASALAH: GAMBAR TIDAK MUNCUL

✅ SOLUSI: Proxy Server HARUS running!

# 🔴 PENYEBAB

Proxy server TIDAK berjalan di port 3000.

Cek dengan command:
netstat -ano | findstr :3000

Jika tidak ada output → proxy belum jalan!

# ✅ LANGKAH FIX

1. Buka Terminal/PowerShell BARU (jangan pakai yang untuk flutter run)

2. Navigate ke folder proxy:
   cd anime-proxy

3. Install dependencies (jika belum):
   npm install

4. Jalankan proxy server:
   npm start

5. Tunggu sampai muncul:
   "Proxy server running at http://localhost:3000"

6. Jangan tutup terminal ini! Biarkan terus jalan di background

7. Di terminal LAIN, jalankan flutter app:
   flutter run

# 🔍 VERIFIKASI

Setelah proxy running, cek di browser:

http://localhost:3000/proxy?target=https%3A%2F%2Fwww.google.com

Jika berhasil → halaman putih/normal
Jika error → ada masalah dengan proxy

# ❓ COMMON ISSUES

Q: "Cannot find 'npm' command"
A: Install Node.js dari https://nodejs.org/

Q: "Port 3000 already in use"
A: Kill existing process atau ganti port:
PORT=3001 npm start
Lalu update di lib/config/environment.dart

Q: "EADDRINUSE: address already in use"
A: Ada process lain menggunakan port 3000
Jalankan: netstat -ano | findstr :3000
Kemudian: taskkill /PID {PID} /F

Q: Masih tidak muncul setelah proxy running?
A: Cek di Flutter console untuk error
Baca: IMAGE_PROXY_SETUP.md

# 📝 PROSEDUR STARTUP (Setiap Kali Jalankan)

TERMINAL 1 - Proxy Server:
$ cd anime-proxy
$ npm start
(Biarkan jalan, jangan close)

TERMINAL 2 - Flutter App:
$ flutter run
(App akan connect ke proxy)

TERMINAL 3 (Optional) - Debug:
$ powershell

> netstat -ano | findstr :3000 # Check proxy
> curl http://localhost:3000/... # Test proxy

# ✨ CHECKLIST SEBELUM JALANKAN

✓ Node.js installed (node --version)
✓ npm installed (npm --version)
✓ anime-proxy folder ada
✓ package.json ada di anime-proxy/
✓ Tidak ada error saat npm install
✓ Port 3000 tidak terpakai
✓ Firewall allow localhost:3000

# 🎯 EXPECTED OUTPUT

Terminal Proxy:

> anime-proxy@1.0.0 start
> node server.js
> Proxy server running at http://localhost:3000
> ← Server listening...

Terminal Flutter:
✓ Build successful
✓ App launches on device
✓ Anime cards show images
✓ No console errors

# 💾 NEXT STEPS

1. Follow prosedur startup di atas
2. Verify proxy running (buka browser ke localhost:3000)
3. Run flutter app
4. Check gambar di anime cards
5. If still no image, baca TROUBLESHOOTING.md

# 📞 NEED HELP?

Baca dokumentasi lengkap:

- IMAGE_PROXY_SETUP.md
- IMPLEMENTATION_SUMMARY.md
- QUICK_START.txt
