@ECHO OFF
REM
REM $Header: tfa/src/orachk_py/orachk.bat /main/16 2018/11/29 09:23:47 apriyada Exp $
REM
REM
REM Copyright (c) 2014, 2018, Oracle and/or its affiliates. 
REM All rights reserved.
REM
REM    NAME
REM      - <one-line expansion of the name>
REM
REM    DESCRIPTION
REM      <short description of component this file declares/defines>
REM
REM    NOTES
REM      Wrapper batch script for ORAchk on windows.
REM
REM    MODIFIED   (MM/DD/YY)
REM		 rojuyal	 02/22/17 - Creation
REM			
REM			

Call :UnsetVars
SET ERRORLEVEL=0

SET PROGRAMN=orachk
SET TOOL=%PROGRAMN%.py

SET TOOLPATH=%~dp0
SET BUILDPATH=%TOOLPATH%build
SET PYDIR=Python37
SET IS_ERROR=0
SET PY_ERROR=0
SET G_ERROR=0
SET BUILD=Python3_windows.zip

if NOT "%RAT_PYBASE%" == "" (
	SET TRAT_PYBASE=%RAT_PYBASE%
    SET TVAR=%RAT_PYBASE:~-1%
    if "%TVAR%" == "\" (
    	SET RAT_PYBASE=%RAT_PYBASE:~0,-1%
    )
	REM SET RAT_CPYBASE=%RAT_PYBASE%::::
	REM SET RAT_CPYBASE="%RAT_CPYBASE:\::::=%"
	REM for /F "delims==" %%i in (%RAT_CPYBASE%) do SET BUILDPATH=%%~dpi
	REM for /f "delims==" %%F in (%RAT_CPYBASE%) do SET PYDIR=%%~nF
)

for %%F in (%TRAT_PYBASE%) do SET BUILDPATH=%%~dpF
for %%F in (%TRAT_PYBASE%) do SET PYDIR=%%~nF

SET SHIPPED_BUILD=1
if exist %BUILDPATH%\%PYDIR% (
	SET SHIPPED_BUILD=0
	SET BUILD=%PYDIR%
) 
if exist %BUILDPATH%\%BUILD% if %SHIPPED_BUILD%==1 (
	Call :UnZipFile "%BUILDPATH%" "%BUILDPATH%\%BUILD%"
)

SET PYTHONEXE=%BUILDPATH%\%PYDIR%\python.exe
if not exist %PYTHONEXE% (
	SET IS_ERROR=1
	SET G_ERROR=1
) else (
    %PYTHONEXE% -V > %TOOLPATH%\.PVERSION
	SET /P VERSION= < %TOOLPATH%\.PVERSION
	DEL %TOOLPATH%\.PVERSION
	if "%VERSION%"=="%VERSION:6=%" (
		SET PY_ERROR=0
	) else (
		SET PY_ERROR=1
		SET G_ERROR=1
	)			 
)

if %G_ERROR% == 0 (
REM ..can add more modules 
	%PYTHONEXE% -c "import winpexpect" 2>NUL
	if ERRORLEVEL 1 (
		ECHO Python error: winpexpect module is missing 
		SET IS_ERROR=1
	)
	%PYTHONEXE% -c "import wmi" 2>NUL
	if ERRORLEVEL 1 (
		ECHO Python error: WMI module is missing
		ECHO
		SET IS_ERROR=1
	)	
	%PYTHONEXE% -c "import win32wnet" 2>NUL
	if ERRORLEVEL 1 (
		ECHO Python error: win32wnet module is missing. 
		SET IS_ERROR=1
	)
	%PYTHONEXE% -c "import win32api" 2>NUL
	if ERRORLEVEL 1 (
		ECHO Python error: win32api module is missing. 
		SET IS_ERROR=1
	)
) else (
	if %PY_ERROR% == 1 (
		SET IS_ERROR=1
	)
)

if %PY_ERROR% == 1 (
ECHO Please use Python 3.7.1 
ECHO
)
if %IS_ERROR% == 1 (
ECHO Issues with Python used to run {program_name}. Please verify if python is correctly configured and available on the system.
ECHO
ECHO Steps for python setup/verification:
ECHO
ECHO a.    Download Python 3.7.1 Windows Installer.^(https://www.python.org/ftp/python/3.7.1/python-3.7.1-amd64.exe^)
ECHO b.    Run the installer. Select 'Customize installation' and then select atleast 'pip' from optional features, click Next.
ECHO c.    Install under C:\%PYDIR% folder^(folder name can vary^), click Next
ECHO d.    Click Next again to 'Customize Python' setup and then click Finish.
ECHO
ECHO       Note: Sometimes %PYDIR% installation throws error for missing 'api-ms-win-crt-runtime-l1-1-0.dll' DLL. In this case please install 'api-ms-win-crt-runtime-l1-1-0.dll' from 'https://support.microsoft.com/en-us/help/2999226/update-for-universal-c-runtime-in-windows'
ECHO	   Also, please verify if 'api-ms-win-crt-runtime-l1-1-0.dll' DLL is present on all nodes in cluster.
ECHO
ECHO e.    Open Control Panel -^> System -^> Advanced system settings -^> Environment Variables
ECHO       Under 'System Variables' click the variable called 'Path' and then 'Edit'. Without deleting any other text, add C:\%PYDIR%;^(include semicolon^) to the beginning of the 'Variable value' and click OK.
ECHO       Click OK on the 'Environment Variables' window
ECHO 
ECHO f.    Install following external modules^( follow mentioned sequence^).
ECHO       1.    pywin32-224.win-amd64-py3.7.exe
ECHO             a.    Download 'pywin32-224.win-amd64-py3.7.exe' from 'https://github.com/mhammond/pywin32/releases/download/b224/pywin32-224.win-amd64-py3.7.exe' and install it.
ECHO             It install external python libraries.modules in site_package directory under Python installation directory.
ECHO                 
ECHO             Last screen with 'finish' button shows Postinstall script output. Please verify if 'pythoncom37.dll' and 'pywintypes37.dll' are copied to 'system32/system' directory or any other external directory^(directory outside Python installation directory^) or not. If both DLLs are copied to 'system32/system'^(or any external^) directory then please copy them from 'system32/system'^( or external^) directory to Python installation directory^('C:\%PYDIR%'^) and 'Lib\site-packages\win32' under installation directory ^(for example: C:\%PYDIR%\Lib\site-packages\win32^).
ECHO			 In case Postinstall script output is empty and 'pythoncom37.dll' and 'pywintypes37.dll' DLLs are not present in Python installation directory^('C:\%PYDIR%'^) and 'Lib\site-packages\win32' under installation directory then copy both mentioned DLLs from ^<Python installation directory^>\Lib\site-packages\pywin32_system32 ^(if present^) to Python installation directory^('C:\%PYDIR%'^) and 'Lib\site-packages\win32' under installation directory ^(for example: C:\%PYDIR%\Lib\site-packages\win32^).  
ECHO
ECHO             In case it fails with below error message, please follow below steps^(in Solution^).
ECHO                   Error: 'close failed in file object destructor:
ECHO                           sys.excepthook is missing
ECHO                           lost sys.stderr'
ECHO                   Solution:
ECHO                       a.    open cmd as Administrator and run cd "c:\%PYDIR%"^(python installation folder path^)
ECHO                       b.    python.exe Scripts\pywin32_postinstall.py -install
ECHO 
ECHO       2.    winpexpect1.5
ECHO             a.    Download 'winpexpect1.5' zip from 'https://pypi.python.org/pypi/winpexpect'.
ECHO             b.    Extract winpexpect. User will get 'winpexpect-1.5' directory.
ECHO             c.    Go inside 'winpexpect-1.5' directory and run 'python setup.py install' command.
ECHO 
ECHO       3.    WMI
ECHO             a.    Download 'WMI' zip from https://pypi.python.org/pypi/WMI/
ECHO             b.    Extract WMI. User will get WMI directory.
ECHO             c.    Go inside 'WMI' directory and run 'python setup.py install' command.
ECHO
ECHO       4.    SET RAT_PYBASE=C:\%PYDIR% ^(folder name can vary^) to point to python installation directory
	REM SET RAT_CPYBASE=
	Call :UnsetVars
	EXIT /b %ERRORLEVEL%
) 

SET RAT_PYBUILD=%BUILD% 
SET RAT_PYDIRNAME=%PYDIR%
SET PATH=%PATH%
SET RAT_PYTHONEXE=%PYTHONEXE%

SET COL_COPIED=0
if exist %TOOLPATH%\.cgrep\collections.dat (
	copy /Y %TOOLPATH%\collections.dat %TOOLPATH%\collections.old.dat > NUL
	if ERRORLEVEL 1 (
		SET COL_COPIED=0
	) else (
		copy /Y %TOOLPATH%\.cgrep\collections.dat %TOOLPATH%\collections.dat > NUL
		if ERRORLEVEL 1 (
			SET COL_COPIED=0
		) else (
			SET COL_COPIED=1
		)
	)
)
if exist %TOOLPATH%\%PROGRAMN%.py (
	%PYTHONEXE% %TOOLPATH%%PROGRAMN%.py %*
) else (
	%PYTHONEXE% %TOOLPATH%%PROGRAMN%.pyc %*
)
if %COL_COPIED%==1 (
	move /Y %TOOLPATH%\collections.old.dat %TOOLPATH%\collections.dat > NUL
)

REM SET RAT_CPYBASE=
Call :UnsetVars
EXIT /b %ERRORLEVEL%

:UnsetVars
SET "PROGRAMN="
SET "TOOL="
SET "TOOLPATH="
SET "TRAT_PYBASE="
SET "TVAR="
SET "IS_ERROR="
SET "PY_ERROR="
SET "G_ERROR="
SET "BUILD="
SET "BUILDPATH="
SET "PYDIR="
SET "PYTHONEXE="
SET "VBS="
SET "RAT_PYBUILD="
SET "RAT_PYDIRNAME="
GOTO:EOF

:UnZipFile <ExtractTo> <newzipfile>
SET VBS="%temp%\_.VBS"
if exist %VBS% del /f /q %VBS%
>%VBS%  ECHO SET fso = CreateObject("Scripting.FileSystemObject")
>>%VBS% ECHO If NOT fso.FolderExists(%1) Then
>>%VBS% ECHO fso.CreateFolder(%1)
>>%VBS% ECHO End If
>>%VBS% ECHO SET objShell = CreateObject("Shell.Application")
>>%VBS% ECHO SET FilesInZip=objShell.NameSpace(%2).items
>>%VBS% ECHO objShell.NameSpace(%1).CopyHere(FilesInZip)
>>%VBS% ECHO SET fso = Nothing
>>%VBS% ECHO SET objShell = Nothing
cscript //nologo %VBS%
if exist %VBS% del /f /q %VBS%
