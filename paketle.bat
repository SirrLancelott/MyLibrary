@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"

rem ---------------------------------------------------------------------------
rem  Dagitilabilir paket uretir:  dagitim\BenimKutuphanem\  ve  .zip
rem  Ciktida derleme araclari gerekmez; hedef makinede yalnizca
rem  SQL Server Express + Visual C++ Runtime aranir.
rem ---------------------------------------------------------------------------

set "PAKET=dagitim\BenimKutuphanem"

echo ============================================
echo  Benim Kutuphanem - Paketleme
echo ============================================
echo.

echo [1/6] Onceki paket temizleniyor...
if exist "dagitim" rmdir /s /q "dagitim"
mkdir "%PAKET%" 2>nul

rem  self-contained: .NET calisma zamani exe'nin yanina gomulur, boylece
rem  hedef makineye ayrica .NET Runtime kurmak gerekmez.
rem  DebugType=none: .pdb hata ayiklama dosyalari pakete girmez.
echo [2/6] API yayinlaniyor (kendi kendine yeterli)...
dotnet publish backend\KutuphaneApi -c Release -r win-x64 --self-contained true ^
    -p:DebugType=none -p:DebugSymbols=false -o "%PAKET%\api" --nologo
if errorlevel 1 goto :hata

echo.
echo [3/6] Masaustu uygulamasi derleniyor...
pushd app
call flutter build windows --release
if errorlevel 1 (popd & goto :hata)
popd

echo.
echo [4/6] Uygulama dosyalari kopyalaniyor...
xcopy "app\build\windows\x64\runner\Release" "%PAKET%\uygulama\" /E /I /Y /Q >nul
if errorlevel 1 goto :hata

rem  DIKKAT: sql\02_veri.sql pakete GIRMEZ. O dosya kisisel kitap listesini
rem  icerir; dagitilan kopya bos bir veritabaniyla baslar.
echo [5/6] Betikler ve belgeler kopyalaniyor...
mkdir "%PAKET%\sql" 2>nul
copy /y "sql\01_sema.sql"            "%PAKET%\sql\"  >nul
copy /y "baslat.bat"                 "%PAKET%\"      >nul
copy /y "dagitim_sablonu\KUR.bat"    "%PAKET%\"      >nul
copy /y "dagitim_sablonu\OKUBENI.txt" "%PAKET%\"     >nul

rem Paketin dogru kuruldugunu dogrula
if not exist "%PAKET%\api\KutuphaneApi.exe"         goto :eksik
if not exist "%PAKET%\uygulama\BenimKutuphanem.exe" goto :eksik
if not exist "%PAKET%\uygulama\flutter_windows.dll" goto :eksik
if not exist "%PAKET%\uygulama\data"                goto :eksik
if not exist "%PAKET%\sql\01_sema.sql"              goto :eksik

rem Kisisel veri sizintisina karsi guvenlik kontrolu
if exist "%PAKET%\sql\02_veri.sql" goto :veriSizdi

echo [6/6] ZIP olusturuluyor...
powershell -NoProfile -Command "Compress-Archive -Path 'dagitim\BenimKutuphanem' -DestinationPath 'dagitim\BenimKutuphanem.zip' -Force"
if errorlevel 1 goto :hata

echo.
echo ============================================
echo  Paket hazir:
echo    dagitim\BenimKutuphanem\        (klasor)
echo    dagitim\BenimKutuphanem.zip     (gonderilecek dosya)
echo.
echo  Veritabani BOS baslar - kisisel kitap listesi pakete dahil degil.
echo.
echo  Karsi tarafta sirasiyla:
echo    1) ZIP'i tamamen cikar
echo    2) KUR.bat  (bir kez)
echo    3) baslat.bat
echo ============================================
pause
exit /b 0

:veriSizdi
echo.
echo HATA: sql\02_veri.sql pakete girmis - bu dosya kisisel kitap
echo listesini icerir ve dagitilmamalidir. Paket iptal edildi.
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
