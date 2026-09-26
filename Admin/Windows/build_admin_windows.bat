@echo off
cd /d "%~dp0..\.."
flutter pub get
flutter build windows --release -t lib/admin_main.dart
if errorlevel 1 exit /b %errorlevel%
mkdir "Admin\Windows" 2>nul
xcopy /E /I /Y "build\windows\x64\runner\Release\*" "Admin\Windows\" >nul
 echo Admin Windows pronto em Admin\Windows
