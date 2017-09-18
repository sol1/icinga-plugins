@echo off set PLUGINDIR="C:\%ProgramData%\icinga2\sbin"
echo "Installing sol1 icinga plugins..."
COPY /Y /V .\*.exe %PLUGINDIR%
