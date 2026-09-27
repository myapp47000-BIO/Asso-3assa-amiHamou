@echo off
REM ايقاف خادم التطبيق المحلي (جمعية حي العسة)
setlocal
echo.
echo   ايقاف الخادم المحلي على المنفذ 8765 ...
powershell -NoProfile -Command ^
  "$c = Get-NetTCPConnection -LocalPort 8765 -State Listen -ErrorAction SilentlyContinue;" ^
  "if ($c) { $c | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue };" ^
  " Write-Host '   [OK] تم ايقاف الخادم.' -ForegroundColor Green }" ^
  "else { Write-Host '   الخادم ليس يعمل اصلا.' }"
echo.
endlocal
