setlocal
rem set path=%path%;cd;C:\Program Files (x86)\Microsoft Visual Studio 10.0\VC\bin;C:\Program Files (x86)\Microsoft Visual Studio 10.0\VC\lib
rem set lib=%lib%;"C:\Program Files (x86)\Microsoft Visual Studio 10.0\VC\lib";"C:\Program Files\Microsoft SDKs\Windows\v7.1\Lib";"C:\Program Files\MATLAB\R2011a\extern\lib\win64\microsoft"
set MATLAB=C:\Program Files\MATLAB\R2011a
set VSINSTALLDIR=C:\Program Files (x86)\Microsoft Visual Studio 10.0
set VCINSTALLDIR=%VSINSTALLDIR%\VC
rem In this case, LINKERDIR is being used to specify the location of the SDK
set LINKERDIR=C:\Program Files\Microsoft SDKs\Windows\v7.1\
set PATH=%VSINSTALLDIR%\Common7\IDE;%VSINSTALLDIR%\Common7\Tools;%VCINSTALLDIR%\bin\amd64;%VCINSTALLDIR%\bin\VCPackages;%LINKERDIR%\Bin\NETFX 4.0 Tools\x64;%LINKERDIR%\Bin\x64;%LINKERDIR%\bin;%MATLAB_BIN%;%PATH%
set INCLUDE=%VCINSTALLDIR%\INCLUDE;%LINKERDIR%\include;%LINKERDIR%\include\gl;%INCLUDE%
set LIB=%VCINSTALLDIR%\LIB\amd64;%LINKERDIR%\lib\x64;%VCINSTALLDIR%\LIB;%MATLAB%\extern\lib\win64;%LIB%
set MW_TARGET_ARCH=win64

echo %PATH%

cl -I"c:\Program Files (x86)\Microsoft Visual Studio 10.0\VC\include" ^
 -I"c:\Program Files\IVI Foundation\IVI\Include" -I"c:\Program Files\IVI Foundation\Visa\Win64\Include" ^
-I"C:\Program Files (x86)\IVI Foundation\VISA\WinNT\include"  ^
/Fohsdio_stream_dual.obj  /O2 /Oy- /DNDEBUG niHSDIO.lib libcmt.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib ^
hsdio_stream_dual.c
