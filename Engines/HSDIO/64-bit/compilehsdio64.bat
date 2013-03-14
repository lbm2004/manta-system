:: MINIMAL SETUP FOR 64-BIT COMPILATION ON WINDOWS 64
setlocal

:: PREPARE GENERAL DIRECTORIES
set VSDIR=C:\Program Files (x86)\Microsoft Visual Studio 10.0
set VCDIR=%VSDIR%\VC
set NIDIR=C:\Program Files\IVI Foundation\VISA\Win64
:: note: two files vpptype.h (from x86 location) & niHSDIOObsolete.h (from web) copied to the directory above

:: LINKERDIR SPECIFIES THE CORRECT SDK (CHANGES BETWEEN 32 AND 64-bit WINDOWS)
set LINKERDIR=C:\Program Files\Microsoft SDKs\Windows\v7.1

:: SET PATH FOR LATER COMPILE
set PATH=%VSDIR%\Common7\IDE;%VCDIR%\bin\amd64;%LINKERDIR%\Bin\x64;%PATH%

:: SET INCLUDE DIRECTORIES
set INCLUDE=%VCDIR%\include;%LINKERDIR%\include;%NIDIR%\include;%INCLUDE%

:: LIB IS USED BY CL.EXE. CONTAINS PATHS FROM NI, VC, AND THE SDK
set LIB=%VCDIR%\LIB\amd64;%LINKERDIR%\lib\x64;%VCDIR%\LIB;%NIDIR%\Lib_x64\msc;%LIB%

:: SET TARGET ARCHITECTURE
set MW_TARGET_ARCH=win64

:: EXECUTE COMPILATION
cl /Fohsdio_stream_cont.obj  /O2 /Oy- /DNDEBUG niHSDIO.lib  libcmt.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib ^
..\hsdio_stream_cont.c