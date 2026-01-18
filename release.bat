@echo off
setlocal EnableExtensions EnableDelayedExpansion

if not "%~1"=="" (
  echo This script does not accept arguments.
  exit /b 1
)

set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
set "APP_NAME=DouyinLiveRecorder"

if not exist "%ROOT%\main.py" (
  echo main.py not found: %ROOT%\main.py
  exit /b 1
)

set "PYTHON_EXE="
set "PYTHON_ARGS="
where python >nul 2>nul && set "PYTHON_EXE=python"
if not defined PYTHON_EXE (
  where py >nul 2>nul && set "PYTHON_EXE=py" && set "PYTHON_ARGS=-3"
)
if not defined PYTHON_EXE (
  echo Python not found in PATH.
  exit /b 1
)

set "POWERSHELL_EXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if not exist "%POWERSHELL_EXE%" (
  set "POWERSHELL_EXE="
  where powershell >nul 2>nul && set "POWERSHELL_EXE=powershell"
  if not defined POWERSHELL_EXE (
    where pwsh >nul 2>nul && set "POWERSHELL_EXE=pwsh"
  )
)
if not defined POWERSHELL_EXE (
  echo PowerShell not found in PATH.
  exit /b 1
)

set "VERSION="
for /f "usebackq tokens=1,* delims==" %%A in ("%ROOT%\main.py") do (
  if not defined VERSION (
    set "VERSION_KEY=%%A"
    set "VERSION_KEY=!VERSION_KEY: =!"
    if /i "!VERSION_KEY!"=="version" set "VERSION=%%B"
  )
)
if defined VERSION (
  set "VERSION=%VERSION: =%"
  set "VERSION=%VERSION:"=%"
)
if not defined VERSION (
  echo version not found in main.py
  exit /b 1
)

call "%PYTHON_EXE%" %PYTHON_ARGS% -m PyInstaller --version >nul 2>nul
if errorlevel 1 (
  echo PyInstaller not installed. Run: %PYTHON_EXE% %PYTHON_ARGS% -m pip install pyinstaller
  exit /b 1
)

set "DIST_ROOT=%ROOT%\dist\win"
set "BUILD_ROOT=%ROOT%\build\win"
set "SPEC_ROOT=%BUILD_ROOT%\spec"

set "DATA_I18N=%ROOT%\i18n"
set "DATA_JS=%ROOT%\src\javascript"

call "%PYTHON_EXE%" %PYTHON_ARGS% -m PyInstaller ^
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

call "%POWERSHELL_EXE%" -NoProfile -Command "Compress-Archive -Path \"%OUTPUT_DIR%\" -DestinationPath \"%ZIP_PATH%\" -Force"
if errorlevel 1 (
  echo Failed to create zip: %ZIP_PATH%
  exit /b 1
)

echo Created: %ZIP_PATH%
endlocal
