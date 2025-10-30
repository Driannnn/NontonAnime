@echo off
REM ============================================================
REM TEST SCRIPT: Debug Image Proxy & API
REM ============================================================
REM Jalankan: test_debug.bat

echo.
echo ============================================================
echo TEST 1: Check Proxy Server (localhost:3000)
echo ============================================================
echo.

echo [*] Testing proxy server connection...
powershell -Command "$ErrorActionPreference='SilentlyContinue'; $result = Invoke-WebRequest -Uri 'http://localhost:3000/proxy?target=https://www.google.com' -TimeoutSec 5; if ($result.StatusCode -eq 200) { Write-Host '[OK] Proxy server running!'; Write-Host 'Status: '$result.StatusCode } else { Write-Host '[ERROR] Proxy not responding' }"

echo.
echo ============================================================
echo TEST 2: Check API Response (https://www.sankavollerei.com/anime/home)
echo ============================================================
echo.

echo [*] Testing API connection...
powershell -Command "$ErrorActionPreference='SilentlyContinue'; $result = Invoke-WebRequest -Uri 'https://www.sankavollerei.com/anime/home' -TimeoutSec 10; if ($result.StatusCode -eq 200) { Write-Host '[OK] API responding!'; Write-Host 'Status: '$result.StatusCode; $data = ConvertFrom-Json $result.Content; Write-Host 'Response type: '($data | Get-Member | Select-Object -First 1).TypeName; Write-Host 'Response keys: '($data | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name) } else { Write-Host '[ERROR] API not responding' }"

echo.
echo ============================================================
echo TEST 3: Test Image URL from API
echo ============================================================
echo.

echo [*] Fetching first anime image URL...
powershell -Command "$ErrorActionPreference='SilentlyContinue'; $result = Invoke-WebRequest -Uri 'https://www.sankavollerei.com/anime/home' -TimeoutSec 10; $data = ConvertFrom-Json $result.Content; $firstKey = ($data | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name)[0]; $firstList = $data.$firstKey; if ($firstList -is [array]) { $firstItem = $firstList[0]; Write-Host 'First item properties:'; $firstItem | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { Write-Host '  - '$_': '($firstItem.$_) }; if ($firstItem.poster) { Write-Host '[OK] Image found: '$firstItem.poster } } else { Write-Host '[ERROR] Could not parse response' }"

echo.
echo ============================================================
echo DIAGNOSTICS COMPLETE
echo ============================================================
echo.
echo If TEST 1 FAILED: Run "cd anime-proxy && npm start"
echo If TEST 2 FAILED: Check internet connection and API availability
echo If TEST 3 FAILED: API response structure is different than expected
echo.

pause
