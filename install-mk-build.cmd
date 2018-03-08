@echo off
set PROGDIR=%~dp0
set SERVER=http://192.168.0.251:8088/files
pushd %TEMP%
%PROGDIR%curl.exe -O %SERVER%/android-ndk-r10e-windows-x86_64.exe
android-ndk-r10e-windows-x86_64.exe
XCOPY /S /Y android-ndk-r10e\* %PROGDIR%
RMDIR /S /Q android-ndk-r10e
popd
