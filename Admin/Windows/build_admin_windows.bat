@echo off
cd /d "%~dp0..\.."
flutter pub get
if errorlevel 1 exit /b %errorlevel%
flutter build windows --release -t lib/admin_main.dart
if errorlevel 1 exit /b %errorlevel%
if exist "Builds\Windows\Admin" rmdir /s /q "Builds\Windows\Admin"
mkdir "Builds\Windows\Admin"
xcopy /E /I /Y "build\windows\x64\runner\Release\*" "Builds\Windows\Admin\" >nul
if exist "Builds\Windows\Admin\jogo_da_velha.exe" ren "Builds\Windows\Admin\jogo_da_velha.exe" "Jogo Da Velha Admin.exe"
echo Admin Windows pronto em Builds\Windows\Admin
echo.
