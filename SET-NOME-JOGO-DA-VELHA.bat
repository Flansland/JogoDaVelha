@echo off
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$files=@('android\app\src\main\AndroidManifest.xml','android\app\src\main\res\values\strings.xml','windows\runner\Runner.rc'); foreach($f in $files){if(Test-Path $f){$s=Get-Content -Raw -LiteralPath $f; $s=$s -replace 'jogo_da_velha','Jogo Da Velha'; Set-Content -LiteralPath $f -Value $s -Encoding UTF8}}"
echo Nome configurado como Jogo Da Velha onde os arquivos da plataforma ja existirem.
pause
