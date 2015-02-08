@echo off
@rem By simon 2014.12.31 文件格式不可以为UTF8
@rem to make Makefile depend list
:main
REM 源文件目录
REM set SRCDIRS=. Control Utils CORE Layout
set SRCDIRS=
set DepDir=
set EXTS=.H .CPP .C .RC
set OBJS=
REM 排除项
set EXCLUDE=%~4

REM 如果你要使用引号括起命令，必须要在前面再加一对空括号，否则会把路径当标题的 makedep.bat "" . ". Control Utils CORE Layout"
REM %~1 - 删除任何引号("); 打印当前路径 chdir
if "%~3" neq "" (
	REM 设置依赖文件生成目录
	if "%~2" neq "" (
	if not exist "%~2" (
		echo %~2 isn't exist
		echo Usage[1]: makedep.bat dir
		echo Usage[2]: makedep.bat
		exit /b 1
	) else ( set DepDir=%~2)
	REM 设置依赖文件生成在当前目录
	) else ( if "%DepDir%" equ "" set DepDir=.)
	REM 设置源码目录
	if "%~3" equ "" (
		if "%SRCDIRS%" equ "" (
			REM 设置默认源码在当前目录
			set SRCDIRS=.
		)
	) else ( set SRCDIRS=%~3)
) else (
REM ======= 使用默认设置 ========
	if "%~1" neq "" (
		if not exist "%~1" (
			echo %~1 isn't exist
			echo Usage[1]: makedep.bat dir
			echo Usage[2]: makedep.bat
			exit /b 1
		) else ( set DepDir=%~1)
		REM 设置依赖文件生成在当前目录
	) else ( if "%DepDir%" equ "" set DepDir=.)
	if "%~2" equ "" (
		if "%SRCDIRS%" equ "" (
			REM 设置默认源码在当前目录
			set SRCDIRS=.
		)
	) else ( set SRCDIRS=%~2)
)

if "%DepDir%" neq ""  (
	echo depDir  = %DepDir%
)
REM %SRCDIRS:~1,-1% 去掉第一个和最后一个字符
if "%SRCDIRS%" neq "" (
	echo srcDirs = %SRCDIRS%
)
REM echo %~dp0
if "%EXCLUDE%" neq "" (
	echo exclude = %EXCLUDE%
) else ( set EXCLUDE=.empty)
REM goto:eof
REM set OUTDIR=.\bin
set curdate=%date:~0,4%-%date:~5,2%-%date:~8,2%[%time:~0,2%:%time:~3,2%]
REM 生成依赖

REM ============== 函数调用 ====================
set srcfile=%DepDir%\msrcfile.lst
set depfile=%DepDir%\mdepfile.lst

call:makeDeplist

REM if "%OBJS%" neq "" (
	REM if exist "%srcfile%" echo %srcfile% was generated
	REM if exist "%depfile%" echo %depfile% was generated	
REM ) else ( 
	REM if exist "%srcfile%" del /f %srcfile%
	REM if exist "%depfile%" del /f %depfile%
	REM echo OBJS is null
	REM 出错返回
	REM exit /b 1
REM )
REM 编译
REM set TAG=%1

REM nmake.exe /nologo /f Makefile.mak %TAG%
rem ============= main end ===================
goto:eof 

REM ========= 方法一 =============
:makeDeplist
set CPPSRCS=
set CSRCS=
set HSRCS=
set RCSRCS=
REM set EXTS=.H .CPP .C
set OBJS2=
set depcmd=
set RESS=
REM set srcfile=%DepDir%\msrcfile.lst
REM set depfile=%DepDir%\mdepfile.lst

REM H%SUFFIX% 后缀
set SUFFIX=SRCS
echo # >%srcfile%
echo # By Simon %curdate% >>%srcfile%
echo # >>%srcfile%

echo # >%depfile%
echo # By Simon %curdate% >>%depfile%
echo # >>%depfile%
SETLOCAL enabledelayedexpansion
rem 支持的 扩展名文件
for %%x in (%EXTS%) do (
	REM 源文件目录
	for %%i in (%SRCDIRS%) do (
		if exist %%i (
			REM echo %%i\*%%x
			if exist "%%i\*%%x" (
				set /a oneTime=1
				rem 列举 /s 子目录
				for /f "delims=" %%j in ('dir /b %%i\*%%x') do (
					set /a isExist=0
					for %%e in (%EXCLUDE%) do (
						if "%%~ne" equ "%%~nj" (
							REM echo %%~nj %%~xj
							set /a isExist=1
						)
					)
					if "!isExist!" neq "1" (
						if "!oneTime!" == "1" (
							rem =============== make srcfile =============
							rem 去掉'.'
							set ddot=%%x
							REM echo !ddot:~1!
							echo.>>%srcfile%
							echo !ddot:~1!%SUFFIX% = ^$^(!ddot:~1!%SUFFIX%^) \>>%srcfile%
						)
						REM echo %%i\%%j \
						echo.			%%i\%%j \>>%srcfile%
						rem *.obj 排除 *.h, *.rc 文件
						if "%%x" neq ".H" (
							if "%%x" neq ".RC" (
								set OBJS=!OBJS! ^$^(OUTDIR^)\%%~nj.obj
								set OBJS2=!OBJS2! %%~nj.obj
								rem == make depfile ==
								if "!oneTime!" == "1" (
									echo.>>%depfile%
									echo {%%i}%%x{^$^(OUTDIR^)}.obj::>>%depfile%
									echo.	^$^(CC^) ^$^(CFLAGS^) ^$^(DEFINE^) ^$^(ENCODE^) ^$^(INCDIRS^) /Fo"$(OUTDIR)\\" ^$^(CDBGFLAGS^) ^$^< >>%depfile%
								)
							REM *.rc 资源文件依赖 add 2015.02.08
							) else (
								set RESS=!RESS! ^$^(OUTDIR^)\%%~nj.res
								if "!oneTime!" == "1" (
									echo.>>%depfile%
									REM $(RC) $(RCFLAGS) $(DEFINE) $(ENCODE) $(INCDIRS) /Fo"$@" $<
									echo {%%i}%%x{^$^(OUTDIR^)}.res:>>%depfile%
									echo.	^$^(RC^) ^$^(RCFLAGS^) ^$^(DEFINE^) ^$^(ENCODE^) ^$^(INCDIRS^) /Fo"$@" ^$^< >>%depfile%
								)
							)
						)
						rem *.h
						if "%%x" equ ".H" (
							set HSRCS=!HSRCS! %%i\%%j
						)
						rem *.rc
						if "%%x" equ ".RC" (
							set RCSRCS=!RCSRCS! %%i\%%j
						)
						rem *.c *.obj
						if "%%x" equ ".C" (
							set CSRCS=!CSRCS! %%i\%%j
							rem *.obj
							REM set OBJS=!OBJS! ^$^(OUTDIR^)\%%~nj.obj
						)
						rem *.cpp *.obj
						if "%%x" equ ".CPP" (
							set CPPSRCS=!CPPSRCS! %%i\%%j
							rem *.obj
							REM set OBJS=!OBJS! ^$^(OUTDIR^)\%%~nj.obj
						)
						if "!oneTime!" == "1" (
							set /a oneTime=0
						)
					)
				)
			)
		)
	)
)
REM if "%HSRCS%" neq "" (
	REM echo %HSRCS%
	REM echo.>>%srcfile%
	REM echo HSRCS = ^$^(HSRCS^) \>>%srcfile%
	REM echo.			%HSRCS%>>%srcfile%
REM )
REM if "%CSRCS%" neq "" (
	REM echo %CSRCS%
	REM echo.>>%srcfile%
	REM echo CSRCS = ^$^(CSRCS^) \>>%srcfile%
	REM echo.			%CSRCS%>>%srcfile%
REM )
REM if "%CPPSRCS%" neq "" (
	REM echo %CPPSRCS%
	REM echo.>>%srcfile%
	REM echo CPPSRCS = ^$^(CPPSRCS^) \>>%srcfile%
	REM echo.			%CPPSRCS%>>%srcfile%
REM )
REM *.obj
REM if "%OBJS%" neq "" (
	REM echo %OBJS%
	echo.>>%srcfile%
	echo ########### 目标文件 #############>>%srcfile%
	echo OBJS = ^$^(OBJS^) \>>%srcfile%
	echo.			%OBJS%>>%srcfile%
REM )
echo.>>%srcfile%
REM === 简单依赖关系: 添加与obj文件名相同的头文件*.h 依赖 ===================
REM 简单依赖关系
REM add 2015.02.06
if "%HSRCS%" neq "" (
	echo.>>%depfile%
	echo ############# 添加与obj文件名相同的头文件*.h 依赖 ###############>>%depfile%
	for %%o in (%OBJS2%) do (
		set depcmd=^$^(OUTDIR^)\%%o:
		REM *.cpp
		for %%s in (%CPPSRCS%) do (
			if "%%~no" equ "%%~ns" (
				set depcmd=!depcmd! %%s
			)
		)
		REM *.c
		for %%s in (%CSRCS%) do (
			if "%%~no" equ "%%~ns" (
				set depcmd=!depcmd! %%s
			)
		)
		REM *.h
		for %%h in (%HSRCS%) do (
			if "%%~no" equ "%%~nh" (
				set depcmd=!depcmd! %%h
				echo.>>%depfile%
				echo !depcmd!>>%depfile%
			)
		)
	)
	REM add 2015.02.08
	if "%RCSRCS%" neq "" (
		REM src file
		echo ########### 资源文件 #############>>%srcfile%
		echo RESS = ^$^(RESS^) \>>%srcfile%
		echo.			!RESS!>>%srcfile%
		REM dep file
		echo.>>%depfile%
		echo ############# 添加*.rc资源依赖 ###############>>%depfile%
		REM *rc资源
		for %%r in (%RCSRCS%) do (
			REM echo %%~nr.res
			set depcmd=^$^(OUTDIR^)\%%~nr.res: %%r
			REM resource.h
			for %%h in (%HSRCS%) do (
				if "%%~nh" equ "resource" (
					set depcmd=!depcmd! %%h
					echo.>>%depfile%
					echo !depcmd!>>%depfile%
				)
			)
		)
	)
)

REM ====================== END ============================
ENDLOCAL
goto:eof

rem ======== 方法二 逐个类型生成 ===========
:makeDeplistByOne
rem to make *.cpp
set CPPSRCS=
set CSRCS=
set HSRCS=
REM set OBJS=
set EXTS=.H .C .CPP
set tmpfile=temp.txt
echo.>%tmpfile%
SETLOCAL enabledelayedexpansion
for %%i in (%SRCDIRS%) do (
	if exist %%i (
		if exist "%%i\*.cpp" (
			echo.>>%tmpfile%
			echo CPPSRCS = ^$^(CPPSRCS^) \>>%tmpfile%
			for /f "delims=" %%j in ('dir /b %%i\*.cpp') do (
				REM echo %%i\%%j \
				set CPPSRCS=!CPPSRCS! %%i\%%j
				set OBJS=!OBJS! ^$^(OUTDIR^)\%%~nj.obj
				echo.		%%i\%%j \>>%tmpfile%
			)
		)
	)
)
if "%CPPSRCS%" neq "" (echo %CPPSRCS%)
rem to make *.c 
for %%i in (%SRCDIRS%) do (
	if exist %%i (
		if exist "%%i\*.c" (
			echo.>>%tmpfile%
			echo CSRCS = ^$^(CSRCS^) \>>%tmpfile%
			for /f "delims=" %%j in ('dir /b %%i\*.c') do (
				REM echo %%i\%%j \
				set CSRCS=!CSRCS! %%i\%%j
				set OBJS=!OBJS! ^$^(OUTDIR^)\%%~nj.obj
				echo.		%%i\%%j \>>%tmpfile%
			)
		)
	)
)
if "%CSRCS%" neq "" echo %CSRCS%
rem to make *.h
for %%i in (%SRCDIRS%) do (
	if exist %%i (
		if exist "%%i\*.h" (
			echo.>>%tmpfile%
			echo HSRCS = ^$^(HSRCS^) \>>%tmpfile%
			for /f "delims=" %%j in ('dir /b %%i\*.h') do (
				REM echo %%i\%%j \
				set HSRCS=!HSRCS! %%i\%%j
				echo.		%%i\%%j \>>%tmpfile%
			)
		)
	)
)
echo %OBJS%

if "%HSRCS%" neq "" echo %HSRCS%
if "%CPPSRCS%" neq "" (
	echo.>>%tmpfile%
	echo # to compile *.cpp>>%tmpfile%
	for %%i in (%CPPSRCS%) do (
		echo ^$^(OUTDIR^)\%%~ni.obj: %%i>>%tmpfile%
		echo.	^$^(CC^) ^$^(CFLAGS^) ^$^(DEFINE^) ^$^(ENCODE^) ^$^(INCDIRS^) /Fo"$(OUTDIR)\\" ^$^(CDBGFLAGS^) ^$^?>>%tmpfile%
	)
)
if "%CSRCS%" neq "" (
	echo.>>%tmpfile%
	echo # to compile *.c>>%tmpfile%
	for %%i in (%CSRCS%) do (
		echo ^$^(OUTDIR^)\%%~ni.obj: %%i>>%tmpfile%
		echo.	^$^(CC^) ^$^(CFLAGS^) ^$^(DEFINE^) ^$^(ENCODE^) ^$^(INCDIRS^) /Fo"$(OUTDIR)\\" ^$^(CDBGFLAGS^) ^$^?>>%tmpfile%
	)
)
echo.>>%tmpfile%
ENDLOCAL
goto:eof
