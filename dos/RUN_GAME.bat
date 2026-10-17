@echo off
setlocal

set "DOSBOX_EXE=%ProgramFiles(x86)%\DOSBox-0.74-3\DOSBox.exe"
if not exist "%DOSBOX_EXE%" set "DOSBOX_EXE=%ProgramFiles%\DOSBox-0.74-3\DOSBox.exe"
set "TASM_HOME=%TEMP%\masm-tasm\bundles\TASM"
set "TASM_BIN=%TASM_HOME%\tasm"
set "GAME_SOURCE=%~dp0soul_dodge.asm"
set "RUN_ROOT=%TEMP%\soul-dodge-dosbox"
set "WORKSPACE=%RUN_ROOT%\workspace"
set "DOSBOX_CONFIG=%RUN_ROOT%\dosbox.conf"

if not exist "%DOSBOX_EXE%" (
  echo DOSBox was not found at:
  echo "%DOSBOX_EXE%"
  echo Edit RUN_GAME.bat if DOSBox is installed in a different location.
  pause
  exit /b 1
)

if not exist "%TASM_BIN%\TASM.EXE" (
  echo TASM was not found at:
  echo "%TASM_HOME%"
  echo Install or restore the masm-tasm TASM bundle first.
  pause
  exit /b 1
)

if not exist "%GAME_SOURCE%" (
  echo The game source was not found:
  echo "%GAME_SOURCE%"
  pause
  exit /b 1
)

if not exist "%WORKSPACE%" mkdir "%WORKSPACE%"
if errorlevel 1 (
  echo Could not create the DOSBox workspace.
  pause
  exit /b 1
)

copy /y "%GAME_SOURCE%" "%WORKSPACE%\SOULDODG.ASM" >nul
if errorlevel 1 (
  echo Could not copy the game source into the DOSBox workspace.
  pause
  exit /b 1
)

(
  echo @echo off
  echo TASM /M2 D:\SOULDODG.ASM ^> D:\TASM.LOG
  echo IF ERRORLEVEL 1 GOTO BUILD_FAILED
  echo TLINK D:\SOULDODG.OBJ,D:\SOULDODG.EXE,NUL; ^> D:\TLINK.LOG
  echo IF ERRORLEVEL 1 GOTO BUILD_FAILED
  echo ECHO Build successful. Starting Soul Dodge...
  echo D:\SOULDODG.EXE
  echo GOTO FINISHED
  echo :BUILD_FAILED
  echo TYPE D:\TASM.LOG
  echo TYPE D:\TLINK.LOG
  echo ECHO Build failed. Check the assembler and linker messages above.
  echo :FINISHED
) > "%WORKSPACE%\RUN.BAT"

(
  echo [sdl]
  echo fullscreen=false
  echo [autoexec]
  echo mount c "%TASM_HOME%"
  echo mount d "%WORKSPACE%"
  echo path c:\tasm
  echo d:
  echo cd \
  echo run.bat
) > "%DOSBOX_CONFIG%"

if errorlevel 1 (
  echo Could not prepare the DOSBox launch files.
  pause
  exit /b 1
)

echo Building and starting Soul Dodge in DOSBox...
echo Close the DOSBox window when you want to exit the game.
start "" "%DOSBOX_EXE%" -conf "%DOSBOX_CONFIG%"
if errorlevel 1 (
  echo DOSBox could not be started.
  pause
  exit /b 1
)

endlocal
