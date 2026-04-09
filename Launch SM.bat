@echo off
REM # This file must be in SM directory
REM --> Config
set run_on_system_startup=true
set python_dir=C:\Users\hashc\AppData\Local\Python\pythoncore-3.14-64
set sm_dir=F:\SM-master
REM Config <--

setlocal enabledelayedexpansion
set full_self_path=%0%
if %run_on_system_startup% == true (
	if not exist "%appdata%\Microsoft\Windows\Start Menu\Programs\Startup\sm_startup_launch.vbs" (
		echo Set WshShell = CreateObject("WScript.Shell"^)>"%appdata%\Microsoft\Windows\Start Menu\Programs\Startup\sm_startup_launch.vbs"
		echo WshShell.Run chr(34^) ^& %full_self_path% ^& Chr(34^), ^0>>"%appdata%\Microsoft\Windows\Start Menu\Programs\Startup\sm_startup_launch.vbs"
		echo Set WshShell = Nothing>>"%appdata%\Microsoft\Windows\Start Menu\Programs\Startup\sm_startup_launch.vbs"
	)
) else (
	if exist "%appdata%\Microsoft\Windows\Start Menu\Programs\Startup\sm_startup_launch.vbs" del /s /q "%appdata%\Microsoft\Windows\Start Menu\Programs\Startup\sm_startup_launch.vbs" >nul
)
:init
cd /D %sm_dir%
if not exist %python_dir%\python.exe echo ERROR^: python.exe not found in python_dir ^(%python_dir%^)& pause& exit
if not exist %sm_dir%\Downloader.py echo ERROR^: Downloader.py not found in sm_dir ^(%sm_dir%^)& pause& exit
if not exist %sm_dir%\Controller.py echo ERROR^: Controller.py not found in sm_dir ^(%sm_dir%^)& pause& exit
set arg=%1
if !arg! == launch_sm (
	"%python_dir%\python.exe" "%sm_dir%\Downloader.py"
	exit
)

:check_if_sm_is_running
call :get_controller_response status
if not defined sm_result (call :launch_new_sm_session) else (goto :menu)

:launch_new_sm_session
echo Launching SM in hidden mode...
powershell (Start-Process '%full_self_path%' -ArgumentList "launch_sm" -WindowStyle Hidden)
ping localhost -n 5 >nul
call :get_controller_response start *
exit

:menu
cls
echo SM is already running in hidden mode
echo --^> Last response from SM:
type "%tmp%\sm_result"
echo ^<--
echo 1. Display status
echo 2. Insert command
echo 3. Start all recordings
echo 4. Stop all recordings
echo 5. Shutdown PC in 5 seconds
choice /C 123456789 /T 10 /M ">" /N /D 9
if errorlevel 9 goto menu
if errorlevel 8 goto menu
if errorlevel 7 goto menu
if errorlevel 6 goto menu
if errorlevel 5 shutdown /s /t 5& echo Press any key to abort& pause >nul& shutdown /a& goto menu 
if errorlevel 4 call :get_controller_response stop *& goto menu
if errorlevel 3 call :get_controller_response start *& goto menu
if errorlevel 2 set /p "command=>"& call :get_controller_response !command!& goto menu
if errorlevel 1 call :get_controller_response status& goto menu

:get_controller_response
set arg1=%1
set arg2=%2
set arg3=%3
if defined arg1 set command=%arg1%
if defined arg2 set command=%command% %arg2%
if defined arg3 set command=%command% %arg3%
if exist %tmp%\sm_result del /s /q %tmp%\sm_result >nul
echo %python_dir%\python.exe %sm_dir%\Controller.py %command% ^>^"%tmp%\sm_result^">"%tmp%\sm_get_controller_response.bat"
echo Awaiting controller response ...
call powershell (Start-Process '%tmp%\sm_get_controller_response.bat' -WindowStyle Hidden)
tasklist |find "%process_id%" >nul
if not errorlevel 1 taskkill /f /im %process_id% >nul
for /f "tokens=* delims=" %%k in ('type "%tmp%\sm_result"') do (set sm_result=%%k)
