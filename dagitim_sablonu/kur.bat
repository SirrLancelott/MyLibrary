@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"

rem ---------------------------------------------------------------------------
rem  Paketteki veritabanini bu bilgisayara yerlestirir.
rem  Yalnizca bir kez, ilk kurulumda calistirilir.
rem ---------------------------------------------------------------------------

set "KAYNAK=%~dp0veri\kutuphane.db"
set "HEDEF_KLASOR=%LOCALAPPDATA%\BenimKutuphanem"
set "HEDEF=%HEDEF_KLASOR%\kutuphane.db"

echo ============================================
echo  Benim Kutuphanem - Veritabani kurulumu
echo ============================================
echo.

if not exist "%KAYNAK%" goto :kaynakYok

rem find.exe tam yolla cagrilir: PATH'te ayni adli baska bir arac olabilir
tasklist /fi "imagename eq BenimKutuphanem.exe" 2>nul | "%SystemRoot%\System32\find.exe" /i "BenimKutuphanem.exe" >nul
if not errorlevel 1 goto :acik

echo Hedef: %HEDEF%
echo.

if not exist "%HEDEF%" goto :kopyala

echo Bu bilgisayarda zaten bir kutuphane var.
echo Devam ederseniz mevcut dosya yedeklenir ve paketteki ile degistirilir.
echo.
set "ONAY="
set /p "ONAY=Devam edilsin mi? (E/H): "
if /i not "%ONAY%"=="E" goto :iptal

for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd-HHmmss"') do set "ZAMAN=%%i"
set "YEDEK=%HEDEF_KLASOR%\yedek-%ZAMAN%"
mkdir "%YEDEK%" 2>nul
move /y "%HEDEF%" "%YEDEK%\" >nul
if errorlevel 1 goto :yedekOlmadi
if exist "%HEDEF%-wal" move /y "%HEDEF%-wal" "%YEDEK%\" >nul
if exist "%HEDEF%-shm" move /y "%HEDEF%-shm" "%YEDEK%\" >nul
echo.
echo Eski kutuphane su klasore tasindi:
echo   %YEDEK%
echo.

:kopyala
if not exist "%HEDEF_KLASOR%" mkdir "%HEDEF_KLASOR%"
copy /y "%KAYNAK%" "%HEDEF%" >nul
if errorlevel 1 goto :yazilamadi

rem Eski WAL artiklari yeni dosyayla eslesmez; kalirsa veri bozulur.
if exist "%HEDEF%-wal" del /q "%HEDEF%-wal"
if exist "%HEDEF%-shm" del /q "%HEDEF%-shm"

echo ============================================
echo  Kutuphane yerlestirildi.
echo.
echo  Simdi BenimKutuphanem.exe dosyasina cift tiklayin.
echo  Giris bilgileriniz eski bilgisayardakiyle ayni.
echo ============================================
echo.
pause
exit /b 0

:iptal
echo.
echo Iptal edildi. Hicbir dosya degismedi.
pause
exit /b 0

:kaynakYok
echo HATA: veri\kutuphane.db bulunamadi.
echo ZIP dosyasini tamamen cikardiginizdan emin olun.
echo.
pause
exit /b 1

:acik
echo HATA: Uygulama su anda acik. Once kapatip tekrar deneyin.
echo.
pause
exit /b 1

:yedekOlmadi
echo.
echo HATA: Mevcut kutuphane yedeklenemedi; hicbir sey degistirilmedi.
echo Uygulamanin kapali oldugundan emin olun.
echo.
pause
exit /b 1

:yazilamadi
echo.
echo HATA: Kopyalama basarisiz oldu.
echo Su klasore yazma izniniz olmayabilir:
echo   %HEDEF_KLASOR%
echo.
pause
exit /b 1
