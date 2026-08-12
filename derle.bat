@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"

echo ============================================
echo  Benim Kutuphanem - Derleme
echo ============================================
echo.

pushd app
call flutter build windows --release
if errorlevel 1 (popd & goto :hata)
popd

echo.
echo ============================================
echo  Derleme tamamlandi.
echo.
echo  Calistirmak icin:
echo    app\build\windows\x64\runner\Release\BenimKutuphanem.exe
echo.
echo  Dagitilabilir paket icin: paketle.bat
echo ============================================
pause
exit /b 0

:hata
echo.
echo HATA: Derleme basarisiz oldu. Yukaridaki mesajlara bakin.
pause
exit /b 1
