@echo off
color 87
title strip tools

set instdir=%CD%

if %build32%==yes (
	FOR /R "%instdir%\local32\bin" %%C IN (*.exe) DO (
		%instdir%\mingw32\bin\strip --strip-all %%C 
		echo.%%C done...
		)
	FOR /R "%instdir%\local32\bin" %%D IN (*.dll) DO (
		%instdir%\mingw32\bin\strip --strip-all %%D 
		echo.%%D done...
		)
	)
	
if %build64%==yes (
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