:: MINIMAL SETUP FOR 32-BIT COMPILATION ON WINDOWS 32
setlocal

:: PREPARE GENERAL DIRECTORIES
set VSDIR=C:\Program Files\Microsoft Visual Studio 10.0
set VCDIR=%VSDIR%\VC
set NIDIR=C:\Program Files\IVI Foundation\VISA\WinNT\

:: LINKERDIR SPECIFIES THE CORRECT SDK (CHANGES BETWEEN 32 AND 64-bit WINDOWS)
set LINKERDIR=C:\Program Files\Microsoft SDKs\Windows\v7.0A\

:: SET PATH FOR LATER COMPILE
set PATH=%VSDIR%\Common7\IDE;%VCDIR%\bin;%PATH%

:: SET INCLUDE DIRECTORIES
set INCLUDE=%VCDIR%\include;%LINKERDIR%\include;%NIDIR%\include;%INCLUDE%

:: LIB IS USED BY CL.EXE. CONTAINS PATHS FROM NI, VC, AND THE SDK
set LIB=%VCDIR%\LIB;%LINKERDIR%\lib;%VCDIR%\LIB;%NIDIR%\Lib\msc;%LIB%

:: SET TARGET ARCHITECTURE
set MW_TARGET_ARCH=win32

:: EXECUTE COMPILATION
cl /Fohsdio_stream_dual.obj  /O2 /Oy- /DNDEBUG niHSDIO.lib libcmt.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib ^
..\hsdio_stream_dual.c