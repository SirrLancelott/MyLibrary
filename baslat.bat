@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"

rem ---------------------------------------------------------------------------
rem  Iki yerlesim de desteklenir:
rem    dagitim     : api\KutuphaneApi.exe      + uygulama\BenimKutuphanem.exe
rem    gelistirme  : backend\yayin\...         + app\build\windows\x64\runner\Release\...
rem  Once dagitim yerlesimine bakilir; boylece paketlenmis kopya kendi
rem  klasorunden sorunsuz calisir.
rem ---------------------------------------------------------------------------
set "API_EXE="
set "APP_EXE="

if exist "api\KutuphaneApi.exe"          set "API_EXE=api\KutuphaneApi.exe"
if exist "uygulama\BenimKutuphanem.exe"  set "APP_EXE=uygulama\BenimKutuphanem.exe"

if not defined API_EXE if exist "backend\yayin\KutuphaneApi.exe" set "API_EXE=backend\yayin\KutuphaneApi.exe"
if not defined APP_EXE if exist "app\build\windows\x64\runner\Release\BenimKutuphanem.exe" set "APP_EXE=app\build\windows\x64\runner\Release\BenimKutuphanem.exe"

if not defined API_EXE goto :derlenmemis
if not defined APP_EXE goto :derlenmemis

rem Flutter uygulamasi Visual C++ calisma zamanina ihtiyac duyar.
if not exist "%SystemRoot%\System32\vcruntime140.dll" goto :vcuyari
if not exist "%SystemRoot%\System32\msvcp140.dll"     goto :vcuyari
goto :basla

:vcuyari
echo.
echo UYARI: Visual C++ Runtime (vcruntime140.dll) bulunamadi.
echo Uygulama acilmazsa "Microsoft Visual C++ Redistributable (x64)"
echo paketini kurup tekrar deneyin.
echo.
pause

:basla
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
if exist "KUR.bat" (
    echo  - Veritabani kurulu mu? Bir kereye mahsus KUR.bat calistirin.
) else (
    echo  - BenimKutuphanem veritabani kurulu mu? sql\00_veritabani_kur.bat
)
echo  - "KutuphaneApi" penceresindeki hata mesajina bakin.
pause
exit /b 1

:derlenmemis
echo.
if exist "derle.bat" (
    echo Once derleme yapilmali. Calistirin: derle.bat
) else (
    echo Paket eksik gorunuyor: api\ ve uygulama\ klasorleri bulunamadi.
    echo ZIP dosyasini tamamen cikardiginizdan emin olun.
)
pause
exit /b 1
