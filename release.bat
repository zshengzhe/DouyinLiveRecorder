@echo off
setlocal EnableExtensions

if not "%~1"=="" (
  echo This script does not accept arguments.
  exit /b 1
)

set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
set "APP_NAME=DouyinLiveRecorder"

set "PYTHON_BIN="
where python >nul 2>nul && set "PYTHON_BIN=python"
if not defined PYTHON_BIN (
  where py >nul 2>nul && set "PYTHON_BIN=py -3"
)
if not defined PYTHON_BIN (
  echo Python not found in PATH.
  exit /b 1
)

for /f "delims=" %%V in ('%PYTHON_BIN% -c "import os, pathlib, re; root=os.environ.get('ROOT', ''); text=pathlib.Path(root, 'main.py').read_text(encoding='utf-8'); m=re.search('version\\s*=\\s*[\"\']([^\"\']+)[\"\']', text); print(m.group(1) if m else '')"') do set "VERSION=%%V"
if not defined VERSION (
  echo version not found in main.py
  exit /b 1
)

call %PYTHON_BIN% -m PyInstaller --version >nul 2>nul
if errorlevel 1 (
  echo PyInstaller not installed. Run: %PYTHON_BIN% -m pip install pyinstaller
  exit /b 1
)

set "DIST_ROOT=%ROOT%\dist\win"
set "BUILD_ROOT=%ROOT%\build\win"
set "SPEC_ROOT=%BUILD_ROOT%\spec"

set "DATA_I18N=%ROOT%\i18n"
set "DATA_JS=%ROOT%\src\javascript"

call %PYTHON_BIN% -m PyInstaller ^
  --noconfirm ^
  --clean ^
  --name "%APP_NAME%" ^
  --onedir ^
  --distpath "%DIST_ROOT%" ^
  --workpath "%BUILD_ROOT%" ^
  --specpath "%SPEC_ROOT%" ^
  --add-data "%DATA_I18N%;i18n" ^
  --add-data "%DATA_JS%;src/javascript" ^
  "%ROOT%\main.py"

set "APP_DIR=%DIST_ROOT%\%APP_NAME%"
if not exist "%APP_DIR%" (
  echo Build output not found: %APP_DIR%
  exit /b 1
)

if exist "%ROOT%\config" (
  xcopy "%ROOT%\config" "%APP_DIR%\config\" /e /i /y >nul
)

if exist "%ROOT%\backup_config" (
  xcopy "%ROOT%\backup_config" "%APP_DIR%\backup_config\" /e /i /y >nul
) else (
  if not exist "%APP_DIR%\backup_config" mkdir "%APP_DIR%\backup_config"
)

if exist "%ROOT%\index.html" copy /y "%ROOT%\index.html" "%APP_DIR%\" >nul
if exist "%ROOT%\README.md" copy /y "%ROOT%\README.md" "%APP_DIR%\" >nul
if exist "%ROOT%\StopRecording.vbs" copy /y "%ROOT%\StopRecording.vbs" "%APP_DIR%\" >nul

del /q "%APP_DIR%\StopRecording.sh" "%APP_DIR%\StopRecording.command" 2>nul

set "DEPS_ROOT=%ROOT%\packaging\deps\win"
set "FFMPEG_SRC=%DEPS_ROOT%\ffmpeg"
set "EXTRAS_SRC=%DEPS_ROOT%\extras"

if exist "%FFMPEG_SRC%" (
  xcopy "%FFMPEG_SRC%" "%APP_DIR%\ffmpeg\" /e /i /y >nul
) else (
  echo Warning: missing ffmpeg directory: %FFMPEG_SRC%
)

if exist "%EXTRAS_SRC%" (
  xcopy "%EXTRAS_SRC%\*" "%APP_DIR%\" /e /i /y >nul
)

set "OUTPUT_NAME=%APP_NAME%_win_%VERSION%"
set "OUTPUT_DIR=%DIST_ROOT%\%OUTPUT_NAME%"
if exist "%OUTPUT_DIR%" (
  echo Output directory already exists: %OUTPUT_DIR%
  echo Please remove it before packaging again.
  exit /b 1
)
move "%APP_DIR%" "%OUTPUT_DIR%" >nul

set "RELEASE_DIR=%ROOT%\release"
set "ZIP_PATH=%RELEASE_DIR%\%OUTPUT_NAME%.zip"
if not exist "%RELEASE_DIR%" mkdir "%RELEASE_DIR%"

powershell -NoProfile -Command "Compress-Archive -Path \"%OUTPUT_DIR%\" -DestinationPath \"%ZIP_PATH%\" -Force"
if errorlevel 1 (
  echo Failed to create zip: %ZIP_PATH%
  exit /b 1
)

echo Created: %ZIP_PATH%
endlocal
