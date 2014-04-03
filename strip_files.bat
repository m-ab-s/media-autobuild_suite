@echo off
color 87
title strip tools

set instdir=%CD%

if exist "%instdir%\local32\bin" (
	FOR /R "%instdir%\local32\bin" %%C IN (*.exe) DO (
		%instdir%\mingw32\bin\strip --strip-all %%C 
		echo.%%C done...
		)
	FOR /R "%instdir%\local32\bin" %%D IN (*.dll) DO (
		%instdir%\mingw32\bin\strip --strip-all %%D 
		echo.%%D done...
		)
	)
	
if exist "%instdir%\local64\bin" (
	FOR /R "%instdir%\local64\bin" %%C IN (*.exe) DO (
		%instdir%\mingw64\bin\strip --strip-all %%C 
		echo.%%C done...
		)
	FOR /R "%instdir%\local64\bin" %%D IN (*.dll) DO (
		%instdir%\mingw64\bin\strip --strip-all %%D 
		echo.%%D done...
		)
	)
echo -------------------------------------------------------------------------------
echo.
echo. striping all bins...
echo.
echo -------------------------------------------------------------------------------
	
pause