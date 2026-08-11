@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"

echo ============================================
echo  Benim Kutuphanem - Derleme
echo ============================================
echo.

echo [1/2] API derleniyor (backend\KutuphaneApi)...
dotnet publish backend\KutuphaneApi -c Release -o backend\yayin
if errorlevel 1 goto :hata

echo.
echo [2/2] Masaustu uygulamasi derleniyor (app)...
pushd app
call flutter build windows --release
if errorlevel 1 (popd & goto :hata)
popd

echo.
echo ============================================
echo  Derleme tamamlandi.
echo  Calistirmak icin: baslat.bat
echo ============================================
pause
exit /b 0

:hata
echo.
echo HATA: Derleme basarisiz oldu. Yukaridaki mesajlara bakin.
pause
exit /b 1
