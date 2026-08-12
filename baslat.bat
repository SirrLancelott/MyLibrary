@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"

set API_EXE=backend\yayin\KutuphaneApi.exe
set APP_EXE=app\build\windows\x64\runner\Release\BenimKutuphanem.exe

if not exist "%API_EXE%" goto :derlenmemis
if not exist "%APP_EXE%" goto :derlenmemis

echo API baslatiliyor (http://127.0.0.1:5199)...
start "KutuphaneApi" /min "%API_EXE%"

echo API'nin hazir olmasi bekleniyor...
set /a deneme=0
:bekle
set /a deneme+=1
powershell -NoProfile -Command "try { Invoke-RestMethod http://127.0.0.1:5199/api/durum -TimeoutSec 2 | Out-Null; exit 0 } catch { exit 1 }" >nul 2>&1
if not errorlevel 1 goto :hazir
if %deneme% GEQ 20 goto :zamanasimi
rem ping ile 1 sn bekle: timeout komutu stdin yonlendirildiginde calismiyor
ping -n 2 127.0.0.1 >nul
goto :bekle

:hazir
echo API hazir. Uygulama aciliyor...
start "" "%APP_EXE%"
echo.
echo Uygulamayi kapattiktan sonra API penceresini de kapatabilirsiniz.
ping -n 4 127.0.0.1 >nul
exit /b 0

:zamanasimi
echo.
echo HATA: API 20 saniyede yanit vermedi.
echo  - SQL Server (SQLEXPRESS) servisi calisiyor mu?
echo  - BenimKutuphanem veritabani kurulu mu? (sql\01_sema.sql ve sql\02_veri.sql)
echo  - "KutuphaneApi" penceresindeki hata mesajina bakin.
pause
exit /b 1

:derlenmemis
echo.
echo Once derleme yapilmali. Calistirin: derle.bat
pause
exit /b 1
