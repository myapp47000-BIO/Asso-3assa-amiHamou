@echo off
REM ============================================================
REM  جمعية حي العسة - تشغيل التطبيق محليا + على الهاتف
REM  الاستعمال:  start.cmd
REM  يفتح الخادم على كل الواجهات، يطبع رابط الهاتف، ثم يفتح المتصفح.
REM  لإيقاف الخادم:  stop.cmd
REM ============================================================
setlocal enabledelayedexpansion
cd /d "%~dp0"
set PORT=8765
set BASE=http://127.0.0.1:%PORT%/
set URL=%BASE%index.html
set DIAG=%BASE%dev/diagnose.html

echo.
echo   جمعية حي العسة  -  خادم محلي
echo   ---------------------------------
echo.

REM --- ايجاد بايثون ---
set "PY="
where py >nul 2>nul && set "PY=py -3"
if not defined PY (
  where python >nul 2>nul && set "PY=python"
)
if not defined PY (
  echo   [X] لم أجد بايثون على الجهاز.
  echo       ثبّته من:  https://www.python.org/downloads/
  echo       فعّل الخيار "Add Python to PATH" أثناء التثبيت.
  echo.
  pause
  exit /b 1
)

powershell -NoProfile -Command "try{$r=Invoke-WebRequest '%URL%' -UseBasicParsing -TimeoutSec 4;exit 0}catch{exit 1}" >nul 2>nul
if not errorlevel 1 goto :ready

echo   تشغيل الخادم على المنفذ %PORT% ...
REM بدون --bind  =>  يستمع على كل الواجهات حتى يصله الهاتف
start "" /min cmd /c "%PY% -m http.server %PORT%"
for /l %%i in (1,1,20) do (
  powershell -NoProfile -Command "try{$r=Invoke-WebRequest '%URL%' -UseBasicParsing -TimeoutSec 2;exit 0}catch{exit 1}" >nul 2>nul
  if not errorlevel 1 goto :ready
  ping -n 1 -w 250 127.0.0.1 >nul
)
echo   [X] فشل تشغيل الخادم. جرّبه يدويا:
echo         cd /d "%~dp0"
echo         %PY% -m http.server %PORT%
echo.
pause
exit /b 1

:ready
echo   [OK] الخادم يعمل.
echo.

REM --- عنوان الهاتف ---
set "LAN="
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
  set "IP=%%a"
  set "IP=!IP: =!"
  if "!IP:~0,7!"=="192.168"    set "LAN=!IP!"
  if "!IP:~0,5!"=="10.0"      if not defined LAN set "LAN=!IP!"
)
if defined LAN (
  echo   على الهاتف (نفس شبكة الواي فاي) افتح:
  echo.
  echo       http://!LAN!:%PORT%/index.html
  echo.
  echo   [مهم] الهاتف والجهاز يجب أن يكونا على نفس الشبكة.
) else (
  echo   لم أتمكن من معرفة عنوان الشبكة.
  echo   شغّل:  ipconfig   وابحث عن IPv4
)

echo.
echo   هذه روابط تشخيص:
echo       %DIAG%
echo.
echo   فتح المتصفح ...
start "" "%URL%"
echo.
endlocal
