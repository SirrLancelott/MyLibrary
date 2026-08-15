@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"

rem ---------------------------------------------------------------------------
rem  Dagitilabilir paket uretir:  dagitim\BenimKutuphanem\  ve  .zip
rem
rem  Uygulama gomulu SQLite kullanir; sunucu sureci, veritabani kurulumu ve
rem  harici bagimlilik yoktur. Karsi tarafta ZIP acilip exe'ye cift tiklanir.
rem ---------------------------------------------------------------------------

set "PAKET=dagitim\BenimKutuphanem"
set "CIKTI=app\build\windows\x64\runner\Release"

echo ============================================
echo  Benim Kutuphanem - Paketleme
echo ============================================
echo.

echo [1/4] Onceki paket temizleniyor...
if exist "dagitim" rmdir /s /q "dagitim"

echo [2/4] Uygulama derleniyor...
pushd app
call flutter build windows --release
if errorlevel 1 (popd & goto :hata)
popd

echo.
echo [3/4] Dosyalar kopyalaniyor...
xcopy "%CIKTI%" "%PAKET%\" /E /I /Y /Q >nul
if errorlevel 1 goto :hata
copy /y "dagitim_sablonu\OKUBENI.txt"   "%PAKET%\" >nul
copy /y "dagitim_sablonu\README-EN.txt" "%PAKET%\" >nul

rem Beklenen dosyalar yerinde mi
if not exist "%PAKET%\BenimKutuphanem.exe"  goto :eksik
if not exist "%PAKET%\flutter_windows.dll"  goto :eksik
if not exist "%PAKET%\sqlite3.dll"          goto :eksik
if not exist "%PAKET%\data"                 goto :eksik
if not exist "%PAKET%\OKUBENI.txt"          goto :eksik
if not exist "%PAKET%\README-EN.txt"        goto :eksik

rem Kisisel veri sizintisina karsi guvenlik kontrolu: uygulama bos
rem veritabaniyla baslar, pakete hicbir .db dosyasi girmemelidir.
if exist "%PAKET%\*.db" goto :veriSizdi

echo [4/4] ZIP olusturuluyor...
powershell -NoProfile -Command "Compress-Archive -Path 'dagitim\BenimKutuphanem' -DestinationPath 'dagitim\BenimKutuphanem.zip' -Force"
if errorlevel 1 goto :hata

echo.
echo ============================================
echo  Paket hazir:
echo    dagitim\BenimKutuphanem.zip
echo.
echo  Karsi tarafta:
echo    1) ZIP'i tamamen cikar
echo    2) BenimKutuphanem.exe dosyasina cift tikla
echo.
echo  Kurulum yok, veritabani kurulumu yok.
echo  Kutuphane bos baslar; giris admin / 1234
echo ============================================
pause
exit /b 0

:veriSizdi
echo.
echo HATA: Pakete bir .db dosyasi girmis. Kisisel kitap listesi
echo dagitilmamalidir. Paket iptal edildi.
rmdir /s /q "dagitim"
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
