@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"

rem ---------------------------------------------------------------------------
rem  KISISEL paket uretir:  dagitim_kisisel\BenimKutuphanem\  ve  .zip
rem
rem  paketle.bat'tan farki: bu paket bu bilgisayardaki GERCEK kitap
rem  listesini de icerir. Kendi ikinci bilgisayarina kurmak icindir,
rem  baskasina verilmez. Baskasina verilecek bos paket icin paketle.bat.
rem ---------------------------------------------------------------------------

set "PAKET=dagitim_kisisel\BenimKutuphanem"
set "CIKTI=app\build\windows\x64\runner\Release"
set "KAYNAK_VERI=%LOCALAPPDATA%\BenimKutuphanem\kutuphane.db"

echo ============================================
echo  Benim Kutuphanem - Kisisel Paketleme
echo ============================================
echo.
echo  DIKKAT: Uretilecek paket kendi kitap listenizi
echo  icerir. Yalnizca kendi bilgisayarlariniz icindir.
echo.

if not exist "%KAYNAK_VERI%" goto :veriYok

rem find.exe tam yolla cagrilir: PATH'te ayni adli baska bir arac olabilir
tasklist /fi "imagename eq BenimKutuphanem.exe" 2>nul | "%SystemRoot%\System32\find.exe" /i "BenimKutuphanem.exe" >nul
if not errorlevel 1 goto :acik

set "ONAY="
set /p "ONAY=Devam edilsin mi? (E/H): "
if /i not "%ONAY%"=="E" goto :iptal
echo.

echo [1/5] Onceki kisisel paket temizleniyor...
if exist "dagitim_kisisel" rmdir /s /q "dagitim_kisisel"

echo [2/5] Uygulama derleniyor...
pushd app
call flutter build windows --release
if errorlevel 1 (popd & goto :hata)
popd

echo.
echo [3/5] Dosyalar kopyalaniyor...
xcopy "%CIKTI%" "%PAKET%\" /E /I /Y /Q >nul
if errorlevel 1 goto :hata
copy /y "dagitim_sablonu\OKUBENI.txt"          "%PAKET%\" >nul
copy /y "dagitim_sablonu\KISISEL-KURULUM.txt"  "%PAKET%\" >nul
copy /y "dagitim_sablonu\kur.bat"              "%PAKET%\" >nul

echo.
echo [4/5] Veritabani anlik goruntusu aliniyor...
python "tools\veri_anlik_goruntu.py" "%PAKET%\veri\kutuphane.db" "%KAYNAK_VERI%"
if errorlevel 1 goto :veriAlinamadi

rem Beklenen dosyalar yerinde mi
if not exist "%PAKET%\BenimKutuphanem.exe"    goto :eksik
if not exist "%PAKET%\flutter_windows.dll"    goto :eksik
if not exist "%PAKET%\sqlite3.dll"            goto :eksik
if not exist "%PAKET%\data"                   goto :eksik
if not exist "%PAKET%\kur.bat"                goto :eksik
if not exist "%PAKET%\KISISEL-KURULUM.txt"    goto :eksik
if not exist "%PAKET%\veri\kutuphane.db"      goto :eksik

echo.
echo [5/5] ZIP olusturuluyor...
powershell -NoProfile -Command "Compress-Archive -Path 'dagitim_kisisel\BenimKutuphanem' -DestinationPath 'dagitim_kisisel\BenimKutuphanem-Kisisel.zip' -Force"
if errorlevel 1 goto :hata

echo.
echo ============================================
echo  Kisisel paket hazir:
echo    dagitim_kisisel\BenimKutuphanem-Kisisel.zip
echo.
echo  Evdeki bilgisayarda:
echo    1) ZIP'i tamamen cikar
echo    2) kur.bat  (bir kez - kitap listesini yerlestirir)
echo    3) BenimKutuphanem.exe
echo.
echo  Bu ZIP kisisel verinizi tasir; paylasmayin.
echo ============================================
pause
exit /b 0

:iptal
echo.
echo Iptal edildi.
pause
exit /b 0

:veriYok
echo HATA: Bu bilgisayarda veritabani bulunamadi:
echo   %KAYNAK_VERI%
echo Once uygulamayi calistirip veri girin.
echo.
pause
exit /b 1

:acik
echo HATA: Uygulama su anda acik. Once kapatip tekrar deneyin.
echo Boylece paketteki kopya eksiksiz olur.
echo.
pause
exit /b 1

:veriAlinamadi
echo.
echo HATA: Veritabani kopyasi alinamadi. Yukaridaki mesaja bakin.
echo Python kurulu degilse python.org uzerinden kurun.
rmdir /s /q "dagitim_kisisel"
pause
exit /b 1

:eksik
echo.
echo HATA: Paket eksik olustu - beklenen dosyalardan biri yok.
echo Yukaridaki derleme ciktisini kontrol edin.
pause
exit /b 1

:hata
echo.
echo HATA: Paketleme basarisiz oldu. Yukaridaki mesajlara bakin.
pause
exit /b 1
