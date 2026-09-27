@echo off
REM ============================================================
REM  جمعية حي العسة - تشغيل التطبيق محليا
REM  الاستعمال:  start.cmd
REM  يفتح الخادم إن لم يكن يعمل، ثم يفتح المتصفح.
REM  لإيقاف الخادم:  stop.cmd
REM ============================================================
setlocal enabledelayedexpansion
cd /d "%~dp0"
set PORT=8765
set URL=http://127.0.0.1:%PORT%/index.html

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

REM --- هل الخادم يعمل؟ ---
powershell -NoProfile -Command "try{$r=Invoke-WebRequest '%URL%' -UseBasicParsing -TimeoutSec 4;exit 0}catch{exit 1}" >nul 2>nul
if errorlevel 1 (
  echo   تشغيل الخادم على المنفذ %PORT% ...
  start "" /min cmd /c "%PY% -m http.server %PORT% --bind 127.0.0.1"
  REM انتظار حتى يستجيب
  for /l %%i in (1,1,20) do (
    powershell -NoProfile -Command "try{$r=Invoke-WebRequest '%URL%' -UseBasicParsing -TimeoutSec 2;exit 0}catch{exit 1}" >nul 2>nul
    if not errorlevel 1 goto :ready
    ping -n 1 -w 250 127.0.0.1 >nul
  )
  echo   [X] فشل تشغيل الخادم. جرّب تشغيله يدويا:
  echo         cd /d "%~dp0"
  echo         %PY% -m http.server %PORT% --bind 127.0.0.1
  echo.
  pause
  exit /b 1
)

:ready
echo   [OK] الخادم يعمل:  %URL%
echo.
echo   تنبيه؟ إن لم يفتح التطبيق راجع صفحة التشخيص:
echo         %URL:~0,-11%dev/diagnose.html
echo.
echo   فتح المتصفح ...
start "" "%URL%"
echo.
endlocal
