@echo off
setlocal enabledelayedexpansion
title Git ¹ÜÀí¹¤¾ß v7.0 - Professional Edition
mode con cols=100 lines=44
chcp 936 >nul 2>&1

set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=!SCRIPT_DIR:~0,-1!"
set "LOG_FILE=!SCRIPT_DIR!\git_tool.log"
set "CONFIG_FILE=!SCRIPT_DIR!\git_tool.ini"
set "CURRENT_DIR=%cd%"
set "COLOR_ENABLED=1"
set "DEBUG_MODE=0"
set "SAFE_MODE=1"
set "MAX_LOG_SIZE=2097152"
set "GIT_TIMEOUT=30"
set "BACKUP_ENABLED=1"
set "CURRENT_BRANCH="
set "AUTO_PUSH=0"
set "DEFAULT_REMOTE=origin"
set "DEFAULT_BRANCH=main"
set "CONFIRM_DANGEROUS=1"
set "LOG_LEVEL=INFO"
set "SHOW_HEADER=1"
set "AUTO_CLEAN_NUL=1"

for /f "tokens=2 delims==." %%a in ('wmic os get localdatetime /value ^| find "="') do set "CUR_DATETIME=%%a"
set "CUR_DATE=!CUR_DATETIME:~0,8!"
set "CUR_TIME=!CUR_DATETIME:~8,6!"

call :INIT_CONFIG
call :INIT_COLORS

echo ping -n 1 -w 2000 github.com >nul 2>&1
if errorlevel 1 (
    if !COLOR_ENABLED!==1 (
        echo !C_YELLOW![¾¯¸æ] GitHub ÍøÂçÁ¬½ÓÊ§°Ü£¬²¿·ÖÔ¶³Ì²Ù×÷¿ÉÄÜ²»¿ÉÓÃ!C_RESET!
    ) else (
        echo [¾¯¸æ] GitHub ÍøÂçÁ¬½ÓÊ§°Ü£¬²¿·ÖÔ¶³Ì²Ù×÷¿ÉÄÜ²»¿ÉÓÃ
    )
) else (
    if !COLOR_ENABLED!==1 (
        echo !C_GREEN![ÐÅÏ¢] GitHub ÍøÂçÁ¬½ÓÕý³£!C_RESET!
    ) else (
        echo [ÐÅÏ¢] GitHub ÍøÂçÁ¬½ÓÕý³£
    )
)

call :CHECK_GIT
call :CHECK_ENVIRONMENT
call :ROTATE_LOG

:MENU
if !AUTO_CLEAN_NUL!==1 (
    if exist "!CURRENT_DIR!\nul" (
        attrib -r -h -s "!CURRENT_DIR!\nul" 2>nul
        del /f /q "!CURRENT_DIR!\nul" 2>nul
        rmdir /s /q "!CURRENT_DIR!\nul" 2>nul
    )
)
for /f "delims=" %%i in ('git branch --show-current 2^>nul') do set "CURRENT_BRANCH=%%i"
cls
if !SHOW_HEADER!==1 (
    call :DISPLAY_HEADER
) else (
    echo.
    echo Git ¹ÜÀí¹¤¾ß v7.0
    echo ================================================================
    echo.
)
call :DISPLAY_MENU
call :GET_INPUT choice
if !choice! geq 1 if !choice! leq 42 (
    call :EXECUTE_OPTION !choice!
) else (
    call :PRINT_ERROR "ÎÞÐ§Ñ¡Ôñ£¬ÇëÊäÈë 1-42 Ö®¼äµÄÊý×Ö"
    call :WAIT_KEY
)
goto MENU

:EXECUTE_OPTION
set "OPTION=%~1"
if !OPTION!==40 goto EXIT_TOOL
if !OPTION!==41 call :OPEN_CMD
if !OPTION!==42 call :OPEN_POWERSHELL
if !OPTION!==1 call :GIT_ADD_ALL
if !OPTION!==2 call :GIT_COMMIT
if !OPTION!==3 call :GIT_ADD_COMMIT
if !OPTION!==4 call :GIT_STATUS
if !OPTION!==5 call :GIT_LOG
if !OPTION!==6 call :GIT_UNSTAGE
if !OPTION!==7 call :GIT_DELETE_REPO
if !OPTION!==8 call :GIT_CHANGE_PATH
if !OPTION!==9 call :GIT_INIT
if !OPTION!==10 call :GIT_ADD_SOURCE
if !OPTION!==11 call :GIT_RESET_HARD
if !OPTION!==12 call :GIT_AMEND
if !OPTION!==13 call :GIT_DIFF
if !OPTION!==14 call :GIT_SHOW
if !OPTION!==15 call :GIT_BRANCH_CREATE
if !OPTION!==16 call :GIT_BRANCH_SWITCH
if !OPTION!==17 call :GIT_BRANCH_LIST
if !OPTION!==18 call :GIT_BRANCH_DELETE
if !OPTION!==19 call :GIT_BRANCH_MERGE
if !OPTION!==20 call :GIT_PUSH
if !OPTION!==21 call :GIT_PULL
if !OPTION!==22 call :GIT_CLONE
if !OPTION!==23 call :GIT_REMOTE_ADD
if !OPTION!==24 call :GIT_REMOTE_LIST
if !OPTION!==25 call :GIT_REMOTE_REMOVE
if !OPTION!==26 call :GIT_STASH_PUSH
if !OPTION!==27 call :GIT_STASH_POP
if !OPTION!==28 call :GIT_STASH_LIST
if !OPTION!==29 call :GIT_STASH_DROP
if !OPTION!==30 call :GIT_CLEAN
if !OPTION!==31 call :GIT_RESTORE
if !OPTION!==32 call :GIT_CONFIG
if !OPTION!==33 call :GIT_ABORT
if !OPTION!==34 call :GIT_REBASE
if !OPTION!==35 call :GIT_TAG
if !OPTION!==36 call :GIT_SUBMODULE
if !OPTION!==37 call :GIT_CHERRY_PICK
if !OPTION!==38 call :GIT_BISECT
if !OPTION!==39 call :GIT_WORKTREE
goto :EOF

:EXIT_TOOL
cls
echo.
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!!C_CYAN!Git ¹ÜÀí¹¤¾ß v7.0!C_RESET!
    echo !C_CYAN!================================================================!C_RESET!
    echo !C_GREEN!ÒÑÍË³ö£¡!C_RESET!
    echo !C_CYAN!================================================================!C_RESET!
) else (
    echo Git ¹ÜÀí¹¤¾ß v7.0
    echo ================================================================
    echo ÒÑÍË³ö£¡
    echo ================================================================
)
echo.
call :LOG_ACTION "EXIT_TOOL"
exit 0

:OPEN_CMD
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!!C_CYAN!ÕýÔÚ´ò¿ª CMD...!C_RESET!
) else (
    echo ÕýÔÚ´ò¿ª CMD...
)
start cmd /k "title Git CMD && cd /d "!CURRENT_DIR!" && echo µ±Ç°Ä¿Â¼: !CURRENT_DIR! && echo Git ÃüÁî¿ÉÓÃ && git --version"
call :LOG_ACTION "OPEN_CMD"
call :WAIT_KEY
goto MENU

:OPEN_POWERSHELL
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!!C_CYAN!ÕýÔÚ´ò¿ª PowerShell...!C_RESET!
) else (
    echo ÕýÔÚ´ò¿ª PowerShell...
)
start powershell -NoExit -Command "Set-Location -Path '!CURRENT_DIR!'; Write-Host 'µ±Ç°Ä¿Â¼: !CURRENT_DIR!' -ForegroundColor Yellow; Write-Host 'Git ÃüÁî¿ÉÓÃ' -ForegroundColor Green; git --version"
call :LOG_ACTION "OPEN_POWERSHELL"
call :WAIT_KEY
goto MENU

:INIT_COLORS
if !COLOR_ENABLED!==1 (
    set "C_RESET=[0m"
    set "C_RED=[91m"
    set "C_GREEN=[92m"
    set "C_YELLOW=[93m"
    set "C_BLUE=[94m"
    set "C_MAGENTA=[95m"
    set "C_CYAN=[96m"
    set "C_WHITE=[97m"
    set "C_BOLD=[1m"
    set "C_DIM=[2m"
) else (
    set "C_RESET="
    set "C_RED="
    set "C_GREEN="
    set "C_YELLOW="
    set "C_BLUE="
    set "C_MAGENTA="
    set "C_CYAN="
    set "C_WHITE="
    set "C_BOLD="
    set "C_DIM="
)
goto :EOF

:INIT_CONFIG
if not exist "!CONFIG_FILE!" (
    echo [DEFAULT]>>"!CONFIG_FILE!"
    echo COLOR=1>>"!CONFIG_FILE!"
    echo SAFE_MODE=1>>"!CONFIG_FILE!"
    echo BACKUP_ENABLED=1>>"!CONFIG_FILE!"
    echo AUTO_PUSH=0>>"!CONFIG_FILE!"
    echo DEFAULT_REMOTE=origin>>"!CONFIG_FILE!"
    echo DEFAULT_BRANCH=main>>"!CONFIG_FILE!"
    echo CONFIRM_DANGEROUS=1>>"!CONFIG_FILE!"
    echo LOG_LEVEL=INFO>>"!CONFIG_FILE!"
    echo SHOW_HEADER=1>>"!CONFIG_FILE!"
    echo AUTO_CLEAN_NUL=1>>"!CONFIG_FILE!"
)
for /f "tokens=1,2 delims==" %%a in ('type "!CONFIG_FILE!" 2^>nul') do (
    if "%%a"=="COLOR" set "COLOR_ENABLED=%%b"
    if "%%a"=="SAFE_MODE" set "SAFE_MODE=%%b"
    if "%%a"=="BACKUP_ENABLED" set "BACKUP_ENABLED=%%b"
    if "%%a"=="AUTO_PUSH" set "AUTO_PUSH=%%b"
    if "%%a"=="DEFAULT_REMOTE" set "DEFAULT_REMOTE=%%b"
    if "%%a"=="DEFAULT_BRANCH" set "DEFAULT_BRANCH=%%b"
    if "%%a"=="CONFIRM_DANGEROUS" set "CONFIRM_DANGEROUS=%%b"
    if "%%a"=="LOG_LEVEL" set "LOG_LEVEL=%%b"
    if "%%a"=="SHOW_HEADER" set "SHOW_HEADER=%%b"
    if "%%a"=="AUTO_CLEAN_NUL" set "AUTO_CLEAN_NUL=%%b"
)
goto :EOF

:CHECK_GIT
where git >nul 2>&1
if errorlevel 1 (
    cls
    call :PRINT_ERROR "Git Î´°²×°»òÎ´Ìí¼Óµ½ PATH »·¾³±äÁ¿"
    echo.
    if !COLOR_ENABLED!==1 (
        echo  !C_YELLOW!Çë·ÃÎÊ https://git-scm.com/download/win ÏÂÔØ°²×°!C_RESET!
        echo  !C_YELLOW!°²×°ºóÖØÐÂ´ò¿ª±¾¹¤¾ß!C_RESET!
    ) else (
        echo  Çë·ÃÎÊ https://git-scm.com/download/win ÏÂÔØ°²×°
        echo  °²×°ºóÖØÐÂ´ò¿ª±¾¹¤¾ß
    )
    echo.
    pause
    exit /b 1
)
for /f "tokens=1-3 delims=." %%a in ('git --version 2^>nul ^| findstr /r "[0-9]"') do (
    set "GIT_MAJOR=%%a"
    set "GIT_MINOR=%%b"
    set "GIT_PATCH=%%c"
)
if !GIT_MAJOR! lss 2 (
    call :PRINT_WARN "Git °æ±¾½Ï¾É£¬½¨ÒéÉý¼¶µ½ 2.x ÒÔÉÏ°æ±¾"
)
goto :EOF

:CHECK_ENVIRONMENT
call :PRINT_INFO "³õÊ¼»¯»·¾³..."
if !AUTO_CLEAN_NUL!==1 (
    powershell -Command "if (Test-Path '!CURRENT_DIR!\nul') { Remove-Item -Path '!CURRENT_DIR!\nul' -Force }" 2>nul
    if exist "!CURRENT_DIR!\nul" (
        attrib -r -h -s "!CURRENT_DIR!\nul" 2>nul
        del /f /q "!CURRENT_DIR!\nul" 2>nul
        rmdir /s /q "!CURRENT_DIR!\nul" 2>nul
        call :PRINT_WARN "ÒÑÇåÀí Windows ±£ÁôÉè±¸ÎÄ¼þ 'nul'"
    )
)
if not exist "!LOG_FILE!" (
    echo Git Tool Log - !date! !time!>"!LOG_FILE!"
    echo ========================================>>"!LOG_FILE!"
)
echo.
if !COLOR_ENABLED!==1 (
    echo !C_CYAN!==================== ÅäÖÃ×´Ì¬ ====================!C_RESET!
) else (
    echo ==================== ÅäÖÃ×´Ì¬ ====================
)
if !SAFE_MODE!==1 (
    if !COLOR_ENABLED!==1 (
        echo !C_GREEN!  °²È«Ä£Ê½        : ÒÑÆôÓÃ!C_RESET!
        echo !C_YELLOW!    - ËùÓÐ²Ù×÷ÐèÒªÈ·ÈÏºó²ÅÄÜÖ´ÐÐ!C_RESET!
        echo !C_YELLOW!    - Î£ÏÕ²Ù×÷ÐèÒªÊäÈë YES ²ÅÄÜ¼ÌÐø!C_RESET!
    ) else (
        echo  °²È«Ä£Ê½        : ÒÑÆôÓÃ
        echo     - ËùÓÐ²Ù×÷ÐèÒªÈ·ÈÏºó²ÅÄÜÖ´ÐÐ
        echo     - Î£ÏÕ²Ù×÷ÐèÒªÊäÈë YES ²ÅÄÜ¼ÌÐø
    )
) else (
    if !COLOR_ENABLED!==1 (
        echo !C_RED!  °²È«Ä£Ê½        : ÒÑ¹Ø±Õ!C_RESET!
        echo !C_RED!    - ¾¯¸æ£ºËùÓÐ²Ù×÷½«Ö±½ÓÖ´ÐÐ£¬ÎÞ·¨³·Ïú£¡!C_RESET!
    ) else (
        echo  °²È«Ä£Ê½        : ÒÑ¹Ø±Õ
        echo     - ¾¯¸æ£ºËùÓÐ²Ù×÷½«Ö±½ÓÖ´ÐÐ£¬ÎÞ·¨³·Ïú£¡
    )
)
if !BACKUP_ENABLED!==1 (
    if !COLOR_ENABLED!==1 (
        echo !C_GREEN!  ×Ô¶¯±¸·Ý        : ÒÑÆôÓÃ!C_RESET!
        echo !C_YELLOW!    - »ØÍË²Ù×÷Ç°»á×Ô¶¯ÔÝ´æµ±Ç°¹¤×÷!C_RESET!
    ) else (
        echo  ×Ô¶¯±¸·Ý        : ÒÑÆôÓÃ
        echo     - »ØÍË²Ù×÷Ç°»á×Ô¶¯ÔÝ´æµ±Ç°¹¤×÷
    )
) else (
    if !COLOR_ENABLED!==1 (
        echo !C_RED!  ×Ô¶¯±¸·Ý        : ÒÑ¹Ø±Õ!C_RESET!
        echo !C_RED!    - ¾¯¸æ£º»ØÍË²Ù×÷Ç°²»»á×Ô¶¯±¸·Ý£¬Êý¾Ý¿ÉÄÜ¶ªÊ§£¡!C_RESET!
    ) else (
        echo  ×Ô¶¯±¸·Ý        : ÒÑ¹Ø±Õ
        echo     - ¾¯¸æ£º»ØÍË²Ù×÷Ç°²»»á×Ô¶¯±¸·Ý£¬Êý¾Ý¿ÉÄÜ¶ªÊ§£¡
    )
)
if !AUTO_PUSH!==1 (
    if !COLOR_ENABLED!==1 (
        echo !C_GREEN!  ×Ô¶¯ÍÆËÍ        : ÒÑÆôÓÃ!C_RESET!
        echo !C_YELLOW!    - Ìá½»³É¹¦ºó»á×Ô¶¯ÍÆËÍµ½Ô¶³Ì!C_RESET!
    ) else (
        echo  ×Ô¶¯ÍÆËÍ        : ÒÑÆôÓÃ
        echo     - Ìá½»³É¹¦ºó»á×Ô¶¯ÍÆËÍµ½Ô¶³Ì
    )
) else (
    if !COLOR_ENABLED!==1 (
        echo !C_DIM!  ×Ô¶¯ÍÆËÍ        : ÒÑ¹Ø±Õ!C_RESET!
    ) else (
        echo  ×Ô¶¯ÍÆËÍ        : ÒÑ¹Ø±Õ
    )
)
if !CONFIRM_DANGEROUS!==1 (
    if !COLOR_ENABLED!==1 (
        echo !C_YELLOW!  Î£ÏÕÈ·ÈÏ        : ÐèÒªÊäÈë YES!C_RESET!
    ) else (
        echo  Î£ÏÕÈ·ÈÏ        : ÐèÒªÊäÈë YES
    )
) else (
    if !COLOR_ENABLED!==1 (
        echo !C_YELLOW!  Î£ÏÕÈ·ÈÏ        : ½öÐèÊäÈë y!C_RESET!
    ) else (
        echo  Î£ÏÕÈ·ÈÏ        : ½öÐèÊäÈë y
    )
)
if !SHOW_HEADER!==1 (
    if !COLOR_ENABLED!==1 (
        echo !C_GREEN!  ÏÔÊ¾±êÌâ        : ÍêÕûÄ£Ê½!C_RESET!
        echo !C_YELLOW!    - ÏÔÊ¾¹¤×÷Ä¿Â¼ºÍ·ÖÖ§ÐÅÏ¢!C_RESET!
    ) else (
        echo  ÏÔÊ¾±êÌâ        : ÍêÕûÄ£Ê½
        echo     - ÏÔÊ¾¹¤×÷Ä¿Â¼ºÍ·ÖÖ§ÐÅÏ¢
    )
) else (
    if !COLOR_ENABLED!==1 (
        echo !C_DIM!  ÏÔÊ¾±êÌâ        : ¼ò½àÄ£Ê½!C_RESET!
    ) else (
        echo  ÏÔÊ¾±êÌâ        : ¼ò½àÄ£Ê½
    )
)
if !AUTO_CLEAN_NUL!==1 (
    if !COLOR_ENABLED!==1 (
        echo !C_GREEN!  ÇåÀí NUL ÎÄ¼þ   : ÒÑÆôÓÃ!C_RESET!
        echo !C_YELLOW!    - ×Ô¶¯ÇåÀí Windows ±£ÁôÉè±¸ÎÄ¼þ!C_RESET!
    ) else (
        echo  ÇåÀí NUL ÎÄ¼þ   : ÒÑÆôÓÃ
        echo     - ×Ô¶¯ÇåÀí Windows ±£ÁôÉè±¸ÎÄ¼þ
    )
) else (
    if !COLOR_ENABLED!==1 (
        echo !C_DIM!  ÇåÀí NUL ÎÄ¼þ   : ÒÑ¹Ø±Õ!C_RESET!
    ) else (
        echo  ÇåÀí NUL ÎÄ¼þ   : ÒÑ¹Ø±Õ
    )
)
if !COLOR_ENABLED!==1 (
    echo !C_CYAN!  ÑÕÉ«ÏÔÊ¾        : ÒÑÆôÓÃ!C_RESET!
    echo !C_CYAN!  Ä¬ÈÏÔ¶³Ì        : !DEFAULT_REMOTE!!C_RESET!
    echo !C_CYAN!  Ä¬ÈÏ·ÖÖ§        : !DEFAULT_BRANCH!!C_RESET!
    echo !C_CYAN!  ÈÕÖ¾¼¶±ð        : !LOG_LEVEL!!C_RESET!
    echo !C_CYAN!========================================================!C_RESET!
) else (
    echo  ÑÕÉ«ÏÔÊ¾        : ÒÑ¹Ø±Õ
    echo  Ä¬ÈÏÔ¶³Ì        : !DEFAULT_REMOTE!
    echo  Ä¬ÈÏ·ÖÖ§        : !DEFAULT_BRANCH!
    echo  ÈÕÖ¾¼¶±ð        : !LOG_LEVEL!
    echo ========================================================
)
echo.
if !COLOR_ENABLED!==1 (
    echo !C_DIM!°´ÈÎÒâ¼ü¼ÌÐø...!C_RESET!
) else (
    echo °´ÈÎÒâ¼ü¼ÌÐø...
)
pause >nul
echo.
goto :EOF

:ROTATE_LOG
if not exist "!LOG_FILE!" goto :EOF
for %%i in ("!LOG_FILE!") do set "LOG_SIZE=%%~zi"
if !LOG_SIZE! gtr !MAX_LOG_SIZE! (
    set "BACKUP_NAME=git_tool_old_!CUR_DATE!_!CUR_TIME!.log"
    if exist "!BACKUP_NAME!" del "!BACKUP_NAME!" 2>nul
    move "!LOG_FILE!" "!BACKUP_NAME!" >nul 2>&1
    echo Log rotated - !date! !time!>"!LOG_FILE!"
    call :PRINT_INFO "ÈÕÖ¾ÒÑÂÖ×ª: !BACKUP_NAME!"
)
goto :EOF

:DISPLAY_HEADER
echo.
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!!C_CYAN!Git ¹ÜÀí¹¤¾ß v7.0 - Professional Edition!C_RESET!
    echo !C_CYAN!================================================================!C_RESET!
    echo !C_BOLD!¹¤×÷Ä¿Â¼: !C_RESET!!C_YELLOW!!CURRENT_DIR!!C_RESET! !C_DIM!(!C_RESET!!C_BLUE!!CURRENT_BRANCH!!C_DIM!)!C_RESET!
    echo !C_CYAN!================================================================!C_RESET!
) else (
    echo Git ¹ÜÀí¹¤¾ß v7.0 - Professional Edition
    echo ================================================================
    echo ¹¤×÷Ä¿Â¼: !CURRENT_DIR! (!CURRENT_BRANCH!)
    echo ================================================================
)
echo.
goto :EOF

:DISPLAY_MENU
if !COLOR_ENABLED!==1 (
    echo !C_CYAN! 1!C_RESET!. Ìí¼ÓËùÓÐÐÞ¸Ä           !C_CYAN!22!C_RESET!. ¿ËÂ¡Ô¶³Ì²Ö¿â
    echo !C_CYAN! 2!C_RESET!. Ìá½»ÐÞ¸Ä               !C_CYAN!23!C_RESET!. Ìí¼ÓÔ¶³Ì²Ö¿â
    echo !C_CYAN! 3!C_RESET!. Ò»¼üÌí¼Ó²¢Ìá½»         !C_CYAN!24!C_RESET!. ²é¿´Ô¶³Ì²Ö¿â
    echo !C_CYAN! 4!C_RESET!. ²é¿´²Ö¿â×´Ì¬           !C_CYAN!25!C_RESET!. É¾³ýÔ¶³Ì²Ö¿â
    echo !C_CYAN! 5!C_RESET!. ²é¿´Ìá½»ÈÕÖ¾           !C_CYAN!26!C_RESET!. ÔÝ´æµ±Ç°¹¤×÷
    echo !C_CYAN! 6!C_RESET!. ³·ÏúÔÝ´æ               !C_CYAN!27!C_RESET!. »Ö¸´ÔÝ´æ¹¤×÷
    echo !C_CYAN! 7!C_RESET!. É¾³ý±¾µØ²Ö¿â           !C_CYAN!28!C_RESET!. ²é¿´ÔÝ´æÁÐ±í
    echo !C_CYAN! 8!C_RESET!. ÇÐ»»¹¤×÷Ä¿Â¼           !C_CYAN!29!C_RESET!. É¾³ýÔÝ´æÏî
    echo !C_CYAN! 9!C_RESET!. ³õÊ¼»¯²Ö¿â             !C_CYAN!30!C_RESET!. ÇåÀíÎ´¸ú×ÙÎÄ¼þ
    echo !C_CYAN!10!C_RESET!. µÝ¹éÌí¼ÓÔ´´úÂë         !C_CYAN!31!C_RESET!. ³·Ïú¹¤×÷ÇøÐÞ¸Ä
    echo !C_CYAN!11!C_RESET!. °²È«»ØÍËÌá½»           !C_CYAN!32!C_RESET!. ÅäÖÃÓÃ»§ÃûÓÊÏä
    echo !C_CYAN!12!C_RESET!. ÐÞ¸ÄÌá½»±¸×¢           !C_CYAN!33!C_RESET!. ·ÅÆúºÏ²¢/±ä»ù³åÍ»
    echo !C_CYAN!13!C_RESET!. ²é¿´ÎÄ¼þ²îÒì           !C_CYAN!34!C_RESET!. ½»»¥Ê½±ä»ù
    echo !C_CYAN!14!C_RESET!. ²é¿´Ìá½»ÏêÇé           !C_CYAN!35!C_RESET!. ±êÇ©¹ÜÀí
    echo !C_CYAN!15!C_RESET!. ´´½¨²¢ÇÐ»»·ÖÖ§         !C_CYAN!36!C_RESET!. ×ÓÄ£¿é¹ÜÀí
    echo !C_CYAN!16!C_RESET!. ÇÐ»»ÏÖÓÐ·ÖÖ§           !C_CYAN!37!C_RESET!. ¼ðÑ¡Ìá½»
    echo !C_CYAN!17!C_RESET!. ²é¿´ËùÓÐ·ÖÖ§           !C_CYAN!38!C_RESET!. ¶þ·Ö²éÕÒ
    echo !C_CYAN!18!C_RESET!. É¾³ý·ÖÖ§               !C_CYAN!39!C_RESET!. ¹¤×÷Ê÷¹ÜÀí
    echo !C_CYAN!19!C_RESET!. ºÏ²¢·ÖÖ§               !C_CYAN!40!C_RESET!. ÍË³ö¹¤¾ß
    echo !C_CYAN!20!C_RESET!. ÍÆËÍµ½Ô¶³Ì²Ö¿â         !C_CYAN!41!C_RESET!. ´ò¿ª CMD ÖÕ¶Ë 
    echo !C_CYAN!21!C_RESET!. À­È¡Ô¶³Ì¸üÐÂ           !C_CYAN!42!C_RESET!. ´ò¿ª PowerShell
    echo !C_CYAN!================================================================!C_RESET!
) else (
    echo  1. Ìí¼ÓËùÓÐÐÞ¸Ä           22. ¿ËÂ¡Ô¶³Ì²Ö¿â
    echo  2. Ìá½»ÐÞ¸Ä               23. Ìí¼ÓÔ¶³Ì²Ö¿â
    echo  3. Ò»¼üÌí¼Ó²¢Ìá½»         24. ²é¿´Ô¶³Ì²Ö¿â
    echo  4. ²é¿´²Ö¿â×´Ì¬           25. É¾³ýÔ¶³Ì²Ö¿â
    echo  5. ²é¿´Ìá½»ÈÕÖ¾           26. ÔÝ´æµ±Ç°¹¤×÷
    echo  6. ³·ÏúÔÝ´æ               27. »Ö¸´ÔÝ´æ¹¤×÷
    echo  7. É¾³ý±¾µØ²Ö¿â           28. ²é¿´ÔÝ´æÁÐ±í
    echo  8. ÇÐ»»¹¤×÷Ä¿Â¼           29. É¾³ýÔÝ´æÏî
    echo  9. ³õÊ¼»¯²Ö¿â             30. ÇåÀíÎ´¸ú×ÙÎÄ¼þ
    echo 10. µÝ¹éÌí¼ÓÔ´´úÂë         31. ³·Ïú¹¤×÷ÇøÐÞ¸Ä
    echo 11. °²È«»ØÍËÌá½»           32. ÅäÖÃÓÃ»§ÃûÓÊÏä
    echo 12. ÐÞ¸ÄÌá½»±¸×¢           33. ·ÅÆúºÏ²¢/±ä»ù³åÍ»
    echo 13. ²é¿´ÎÄ¼þ²îÒì           34. ½»»¥Ê½±ä»ù
    echo 14. ²é¿´Ìá½»ÏêÇé           35. ±êÇ©¹ÜÀí
    echo 15. ´´½¨²¢ÇÐ»»·ÖÖ§         36. ×ÓÄ£¿é¹ÜÀí
    echo 16. ÇÐ»»ÏÖÓÐ·ÖÖ§           37. ¼ðÑ¡Ìá½»
    echo 17. ²é¿´ËùÓÐ·ÖÖ§           38. ¶þ·Ö²éÕÒ
    echo 18. É¾³ý·ÖÖ§               39. ¹¤×÷Ê÷¹ÜÀí
    echo 19. ºÏ²¢·ÖÖ§               40. ÍË³ö¹¤¾ß
    echo 20. ÍÆËÍµ½Ô¶³Ì²Ö¿â         41. ´ò¿ª CMD ÖÕ¶Ë
    echo 21. À­È¡Ô¶³Ì¸üÐÂ           42. ´ò¿ª PowerShell
    echo ================================================================
)
echo.
goto :EOF

:GET_INPUT
if !COLOR_ENABLED!==1 (
    set /p "%~1=!C_BOLD!!C_WHITE!ÇëÑ¡Ôñ¹¦ÄÜ [1-42]£º!C_RESET!"
) else (
    set /p "%~1=ÇëÑ¡Ôñ¹¦ÄÜ [1-42]£º"
)
if "!%~1!"=="" set "%~1=0"
echo !%~1!|findstr /r "^[0-9][0-9]*$" >nul
if errorlevel 1 set "%~1=0"
goto :EOF

:CHECK_REPO
cd /d "!CURRENT_DIR!" 2>nul
if !AUTO_CLEAN_NUL!==1 (
    if exist "!CURRENT_DIR!\nul" (
        attrib -r -h -s "!CURRENT_DIR!\nul" 2>nul
        del /f /q "!CURRENT_DIR!\nul" 2>nul
        rmdir /s /q "!CURRENT_DIR!\nul" 2>nul
    )
)
git rev-parse --git-dir >nul 2>&1
if errorlevel 1 (
    call :PRINT_ERROR "µ±Ç°Ä¿Â¼²»ÊÇ Git ²Ö¿â"
    echo.
    call :PRINT_INFO "ÇëÖ´ÐÐ [9] ³õÊ¼»¯²Ö¿â »ò [8] ÇÐ»»µ½ÕýÈ·µÄÄ¿Â¼"
    call :WAIT_KEY
    goto MENU
)
goto :EOF

:PRINT_INFO
if !COLOR_ENABLED!==1 (
    echo !C_BLUE![ÐÅÏ¢]!C_RESET! %~1
) else (
    echo [ÐÅÏ¢] %~1
)
goto :EOF

:PRINT_SUCCESS
if !COLOR_ENABLED!==1 (
    echo !C_GREEN![³É¹¦]!C_RESET! %~1
) else (
    echo [³É¹¦] %~1
)
goto :EOF

:PRINT_WARN
if !COLOR_ENABLED!==1 (
    echo !C_YELLOW![¾¯¸æ]!C_RESET! %~1
) else (
    echo [¾¯¸æ] %~1
)
goto :EOF

:PRINT_ERROR
if !COLOR_ENABLED!==1 (
    echo !C_RED![´íÎó]!C_RESET! %~1
) else (
    echo [´íÎó] %~1
)
goto :EOF

:WAIT_KEY
echo.
if !COLOR_ENABLED!==1 (
    echo !C_DIM!°´ÈÎÒâ¼ü¼ÌÐø...!C_RESET!
) else (
    echo °´ÈÎÒâ¼ü¼ÌÐø...
)
pause >nul
goto :EOF

:LOG_ACTION
if "!LOG_LEVEL!"=="DEBUG" (
    echo !date! !time! - %~1 >> "!LOG_FILE!" 2>nul
) else if "!LOG_LEVEL!"=="INFO" (
    echo !date! !time! - %~1 >> "!LOG_FILE!" 2>nul
)
goto :EOF

:CONFIRM_ACTION
if !SAFE_MODE!==1 (
    if !COLOR_ENABLED!==1 (
        set /p "confirm=!C_YELLOW!È·ÈÏÖ´ÐÐ´Ë²Ù×÷£¿[y/N]£º!C_RESET!"
    ) else (
        set /p "confirm=È·ÈÏÖ´ÐÐ´Ë²Ù×÷£¿[y/N]£º"
    )
    if /i not "!confirm!"=="y" if /i not "!confirm!"=="yes" (
        call :PRINT_WARN "²Ù×÷ÒÑÈ¡Ïû"
        call :WAIT_KEY
        goto MENU
    )
)
goto :EOF

:CONFIRM_DANGEROUS
if !SAFE_MODE!==1 (
    if !CONFIRM_DANGEROUS!==1 (
        if !COLOR_ENABLED!==1 (
            set /p "confirm=!C_RED!Î£ÏÕ²Ù×÷£¡ÊäÈë YES ¼ÌÐø£¬ÆäËûÈ¡Ïû£º!C_RESET!"
        ) else (
            set /p "confirm=Î£ÏÕ²Ù×÷£¡ÊäÈë YES ¼ÌÐø£¬ÆäËûÈ¡Ïû£º"
        )
        if /i not "!confirm!"=="YES" if /i not "!confirm!"=="y" (
            call :PRINT_WARN "²Ù×÷ÒÑÈ¡Ïû"
            call :WAIT_KEY
            goto MENU
        )
    ) else (
        if !COLOR_ENABLED!==1 (
            set /p "confirm=!C_YELLOW!È·ÈÏÖ´ÐÐ£¿[y/N]£º!C_RESET!"
        ) else (
            set /p "confirm=È·ÈÏÖ´ÐÐ£¿[y/N]£º"
        )
        if /i not "!confirm!"=="y" if /i not "!confirm!"=="yes" (
            call :PRINT_WARN "²Ù×÷ÒÑÈ¡Ïû"
            call :WAIT_KEY
            goto MENU
        )
    )
)
goto :EOF

:GIT_ADD_ALL
call :CHECK_REPO
if !AUTO_CLEAN_NUL!==1 (
    if exist "!CURRENT_DIR!\nul" (
        attrib -r -h -s "!CURRENT_DIR!\nul" 2>nul
        del /f /q "!CURRENT_DIR!\nul" 2>nul
        rmdir /s /q "!CURRENT_DIR!\nul" 2>nul
    )
    git ls-files --cached | findstr /x "nul" >nul
    if not errorlevel 1 (
        git rm --cached -f --ignore-unmatch nul 2>nul
    )
)
git status --porcelain 2>nul | findstr . >nul
if errorlevel 1 (
    call :PRINT_WARN "Ã»ÓÐ·¢ÏÖÈÎºÎÐÞ¸Ä"
    call :WAIT_KEY
    goto MENU
)
call :PRINT_INFO "ÕýÔÚÌí¼ÓËùÓÐÐÞ¸Ä..."
git add . 2>&1
if errorlevel 1 (
    call :PRINT_ERROR "Ìí¼ÓÊ§°Ü"
    call :LOG_ACTION "ADD_ALL_FAILED"
) else (
    call :PRINT_SUCCESS "ÒÑÌí¼ÓËùÓÐÐÞ¸Ä"
    call :LOG_ACTION "ADD_ALL_SUCCESS"
)
call :WAIT_KEY
goto MENU

:GIT_COMMIT
call :CHECK_REPO
git diff --cached --name-only 2>nul | findstr . >nul
if errorlevel 1 (
    call :PRINT_WARN "ÔÝ´æÇøÎª¿Õ£¬ÇëÏÈÌí¼ÓÎÄ¼þ"
    call :WAIT_KEY
    goto MENU
)
set "commit_msg="
if !COLOR_ENABLED!==1 (
    echo ÇëÊäÈëÌá½»±¸×¢£¨Ö§³Ö¶àÐÐ£¬¿ÕÐÐ½áÊø£©£º
) else (
    echo !C_CYAN!ÇëÊäÈëÌá½»±¸×¢£¨Ö§³Ö¶àÐÐ£¬¿ÕÐÐ½áÊø£©£º!C_RESET!
)
set "commit_msg="
:COMMIT_MSG_LOOP
set "line="
set /p "line="
if "!line!"=="" goto :COMMIT_MSG_DONE
set "commit_msg=!commit_msg!!line! "
goto :COMMIT_MSG_LOOP
:COMMIT_MSG_DONE
if "!commit_msg!"=="" set "commit_msg=¸üÐÂ´úÂë !date!"
if !COLOR_ENABLED!==1 (
    echo !C_BLUE!Ìá½»±¸×¢: !C_RESET!!commit_msg!
) else (
    echo Ìá½»±¸×¢: !commit_msg!
)
git commit -m "!commit_msg!" 2>&1
if errorlevel 1 (
    call :PRINT_ERROR "Ìá½»Ê§°Ü"
    call :LOG_ACTION "COMMIT_FAILED"
) else (
    call :PRINT_SUCCESS "Ìá½»³É¹¦"
    git log --oneline -1 2>nul
    call :LOG_ACTION "COMMIT_SUCCESS: !commit_msg!"
    if !AUTO_PUSH!==1 (
        call :PRINT_INFO "×Ô¶¯ÍÆËÍÖÐ..."
        git push 2>&1
    )
)
call :WAIT_KEY
goto MENU

:GIT_ADD_COMMIT
call :CHECK_REPO
if !AUTO_CLEAN_NUL!==1 (
    if exist "!CURRENT_DIR!\nul" (
        attrib -r -h -s "!CURRENT_DIR!\nul" 2>nul
        del /f /q "!CURRENT_DIR!\nul" 2>nul
        rmdir /s /q "!CURRENT_DIR!\nul" 2>nul
    )
    git ls-files --cached | findstr /x "nul" >nul
    if not errorlevel 1 (
        git rm --cached -f --ignore-unmatch nul 2>nul
    )
)
git status --porcelain 2>nul | findstr . >nul
if errorlevel 1 (
    call :PRINT_WARN "Ã»ÓÐ·¢ÏÖÈÎºÎÐÞ¸Ä"
    call :WAIT_KEY
    goto MENU
)
call :PRINT_INFO "ÕýÔÚÌí¼Ó²¢Ìá½»..."
git add . 2>&1
if errorlevel 1 (
    call :PRINT_ERROR "Ìí¼ÓÊ§°Ü"
    call :WAIT_KEY
    goto MENU
)
set "commit_msg="
if !COLOR_ENABLED!==1 (
    set /p "commit_msg=ÇëÊäÈëÌá½»±¸×¢£º"
) else (
    set /p "commit_msg=!C_CYAN!ÇëÊäÈëÌá½»±¸×¢£º!C_RESET!"
)
if "!commit_msg!"=="" set "commit_msg=ÅúÁ¿Ìá½» !date!"
git commit -m "!commit_msg!" 2>&1
if errorlevel 1 (
    call :PRINT_ERROR "Ìá½»Ê§°Ü"
    call :LOG_ACTION "ADD_COMMIT_FAILED"
) else (
    call :PRINT_SUCCESS "Ìá½»³É¹¦"
    git log --oneline -1 2>nul
    call :LOG_ACTION "ADD_COMMIT_SUCCESS: !commit_msg!"
    if !AUTO_PUSH!==1 (
        call :PRINT_INFO "×Ô¶¯ÍÆËÍÖÐ..."
        git push 2>&1
    )
)
call :WAIT_KEY
goto MENU

:GIT_STATUS
call :CHECK_REPO
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!²Ö¿â×´Ì¬£º!C_RESET!
) else (
    echo ²Ö¿â×´Ì¬£º
)
echo.
git status 2>&1
call :WAIT_KEY
goto MENU

:GIT_LOG
call :CHECK_REPO
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!Ìá½»ÀúÊ·£¨×î½ü20Ìõ£©£º!C_RESET!
) else (
    echo Ìá½»ÀúÊ·£¨×î½ü20Ìõ£©£º
)
echo.
git log --oneline --graph --decorate --all -20 2>&1
echo.
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!ÏêÏ¸ÈÕÖ¾£¨×î½ü10Ìõ£©£º!C_RESET!
    git log --pretty=format:"!C_CYAN!%%h!C_RESET! !C_GREEN!%%ad!C_RESET! !C_YELLOW!%%an!C_RESET!%%n%%s%%n" --date=short -10 2>&1
) else (
    echo ÏêÏ¸ÈÕÖ¾£¨×î½ü10Ìõ£©£º
    git log --pretty=format:"%%h %%ad %%an%%n%%s%%n" --date=short -10 2>&1
)
call :WAIT_KEY
goto MENU

:GIT_UNSTAGE
call :CHECK_REPO
git diff --cached --name-only 2>nul | findstr . >nul
if errorlevel 1 (
    call :PRINT_WARN "ÔÝ´æÇøÎª¿Õ"
    call :WAIT_KEY
    goto MENU
)
call :CONFIRM_ACTION
call :PRINT_INFO "ÕýÔÚ³·ÏúÔÝ´æ..."
git reset 2>&1
if errorlevel 1 (
    call :PRINT_ERROR "³·ÏúÊ§°Ü"
    call :LOG_ACTION "UNSTAGE_FAILED"
) else (
    call :PRINT_SUCCESS "ÒÑ³·ÏúÔÝ´æ"
    call :LOG_ACTION "UNSTAGE_SUCCESS"
)
call :WAIT_KEY
goto MENU

:GIT_DELETE_REPO
call :PRINT_ERROR "´Ë²Ù×÷½«ÓÀ¾ÃÉ¾³ýÕû¸ö Git ²Ö¿â"
call :CONFIRM_DANGEROUS
cd /d "!CURRENT_DIR!" 2>nul
if not exist ".git" (
    call :PRINT_WARN "µ±Ç°Ä¿Â¼²»ÊÇ Git ²Ö¿â"
    call :WAIT_KEY
    goto MENU
)
call :PRINT_INFO "ÕýÔÚÉ¾³ý Git ²Ö¿â..."
call :LOG_ACTION "DELETE_REPO_START"
rmdir /s /q ".git" 2>nul
if not exist ".git" (
    call :PRINT_SUCCESS "Git ²Ö¿âÒÑÉ¾³ý"
    if exist ".gitignore" (
        del /f /q ".gitignore" 2>nul
        call :PRINT_INFO ".gitignore ÒÑÉ¾³ý"
    )
    call :LOG_ACTION "DELETE_REPO_SUCCESS"
) else (
    call :PRINT_ERROR "É¾³ýÊ§°Ü£¬³¢ÊÔÇ¿ÖÆÉ¾³ý..."
    takeown /f ".git" /r /d y >nul 2>&1
    icacls ".git" /grant administrators:F /t >nul 2>&1
    rmdir /s /q ".git" 2>nul
    if not exist ".git" (
        call :PRINT_SUCCESS "Git ²Ö¿âÒÑÇ¿ÖÆÉ¾³ý"
        call :LOG_ACTION "DELETE_REPO_FORCED"
    ) else (
        call :PRINT_ERROR "É¾³ýÊ§°Ü£¬ÇëÊÖ¶¯É¾³ý .git ÎÄ¼þ¼Ð"
    )
)
call :WAIT_KEY
goto MENU

:GIT_CHANGE_PATH
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!µ±Ç°Â·¾¶£º!C_RESET!!CURRENT_DIR!
) else (
    echo µ±Ç°Â·¾¶£º!CURRENT_DIR!
)
set "new_path="
if !COLOR_ENABLED!==1 (
    set /p "new_path=!C_CYAN!ÇëÊäÈëÐÂÂ·¾¶£º!C_RESET!"
) else (
    set /p "new_path=ÇëÊäÈëÐÂÂ·¾¶£º"
)
if "!new_path!"=="" (
    call :PRINT_WARN "²Ù×÷ÒÑÈ¡Ïû"
    call :WAIT_KEY
    goto MENU
)
set "new_path=!new_path:"=!"
if not exist "!new_path!\" (
    call :PRINT_ERROR "Â·¾¶²»´æÔÚ"
    call :WAIT_KEY
    goto MENU
)
cd /d "!new_path!" 2>nul
if errorlevel 1 (
    call :PRINT_ERROR "ÎÞ·¨ÇÐ»»µ½Ä¿Â¼"
    call :WAIT_KEY
    goto MENU
)
set "CURRENT_DIR=!new_path!"
call :PRINT_SUCCESS "ÒÑÇÐ»»µ½: !CURRENT_DIR!"
call :LOG_ACTION "CHANGE_PATH: !CURRENT_DIR!"
call :WAIT_KEY
goto MENU

:GIT_INIT
cd /d "!CURRENT_DIR!" 2>nul
if exist ".git" (
    call :PRINT_WARN "µ±Ç°Ä¿Â¼ÒÑ¾­ÊÇ Git ²Ö¿â"
    if !COLOR_ENABLED!==1 (
        set /p "confirm=!C_YELLOW!ÊÇ·ñÖØÐÂ³õÊ¼»¯£¿[y/N]£º!C_RESET!"
    ) else (
        set /p "confirm=ÊÇ·ñÖØÐÂ³õÊ¼»¯£¿[y/N]£º"
    )
    if /i not "!confirm!"=="y" if /i not "!confirm!"=="yes" (
        call :PRINT_WARN "²Ù×÷ÒÑÈ¡Ïû"
        call :WAIT_KEY
        goto MENU
    )
    call :PRINT_INFO "ÕýÔÚÉ¾³ý¾É²Ö¿â..."
    rmdir /s /q ".git" 2>nul
    if exist ".git" (
        call :PRINT_ERROR "É¾³ýÊ§°Ü"
        call :WAIT_KEY
        goto MENU
    )
)
call :PRINT_INFO "ÕýÔÚ³õÊ¼»¯ Git ²Ö¿â..."
git init --initial-branch=!DEFAULT_BRANCH! 2>&1
if errorlevel 1 (
    call :PRINT_ERROR "³õÊ¼»¯Ê§°Ü"
    call :WAIT_KEY
    goto MENU
)
call :PRINT_SUCCESS "Git ²Ö¿â³õÊ¼»¯Íê³É"
call :CREATE_GITIGNORE
git add ".gitignore" 2>nul
call :PRINT_INFO ".gitignore ÒÑÌí¼Óµ½ÔÝ´æÇø"
call :LOG_ACTION "INIT_REPO"
call :WAIT_KEY
goto MENU

:CREATE_GITIGNORE
if exist ".gitignore" goto :EOF
(
echo # ========== ²Ù×÷ÏµÍ³
echo Thumbs.db
echo ehthumbs.db
echo Desktop.ini
echo .DS_Store
echo .Spotlight-V100
echo .Trashes
echo nul
echo /nul
echo CON
echo PRN
echo AUX
echo LPT1
echo LPT2
echo LPT3
echo LPT4
echo LPT5
echo LPT6
echo LPT7
echo LPT8 
echo COM1
echo COM2
echo COM3
echo COM4
echo COM5
echo COM6
echo COM7
echo COM8
echo COM9
echo.
echo # ========== IDE ºÍ±à¼­Æ÷
echo .vscode/
echo .idea/
echo .vs/
echo *.swp
echo *.swo
echo *~
echo *.bak
echo *.tmp
echo .project
echo .classpath
echo .settings/
echo.
echo # ========== ¹¹½¨²úÎï
echo *.exe
echo *.dll
echo *.so
echo *.dylib
echo *.class
echo *.o
echo *.obj
echo *.pdb
echo *.pyc
echo *.pyo
echo __pycache__/
echo *.jar
echo *.war
echo *.ear
echo target/
echo build/
echo dist/
echo out/
echo bin/
echo.
echo # ========== ÈÕÖ¾ÎÄ¼þ
echo *.log
echo logs/
echo *.pid
echo.
echo # ========== Ñ¹ËõÎÄ¼þ
echo *.zip
echo *.rar
echo *.7z
echo *.tar
echo *.gz
echo *.bz2
echo *.xz
echo.
echo # ========== ÒÀÀµ¹ÜÀí
echo node_modules/
echo .pnpm-store/
echo vendor/
echo packages/
echo *.egg-info/
echo .mypy_cache/
echo .pytest_cache/
echo .coverage
echo htmlcov/
echo.
echo # ========== »·¾³ÅäÖÃ
echo .env
echo .env.local
echo .env.*.local
echo .env.production
echo .env.development
echo *.local
echo.
echo # ========== Êý¾Ý¿â
echo *.db
echo *.sqlite
echo *.sqlite3
echo.
echo # ========== »º´æ
echo .cache/
echo *.cache
echo *.min.js
echo *.min.css
echo *.map
echo.
echo # ========== ÏµÍ³ÎÄ¼þ
echo .fuse_hidden*
echo .directory
echo .lock-wscript
echo .npm/
echo .yarn/
echo package-lock.json
echo yarn.lock
echo pnpm-lock.yaml
) > .gitignore
goto :EOF

:GIT_ADD_SOURCE
call :CHECK_REPO
call :PRINT_INFO "ÕýÔÚÉ¨ÃèÔ´´úÂëÎÄ¼þ..."
set "SOURCE_EXTS=.c .cpp .cc .cxx .h .hpp .hxx .java .py .pyw .js .ts .jsx .tsx .go .rs .rb .php .html .htm .css .scss .less .vue .svelte .xml .json .yaml .yml .toml .ini .cfg .conf .sh .bash .zsh .fish .ps1 .pl .pm .lua .r .m .swift .kt .kts .dart .erl .hrl .ex .exs .clj .cljs .edn .scala .sbt .groovy .gradle .lisp .cl .el .sql .prisma .proto .md .markdown .txt .rst .adoc .asciidoc .org .tex .latex .bib"
set "FILE_COUNT=0"
set "ADD_COUNT=0"
set "TEMP_FILE=!SCRIPT_DIR!\temp_filelist.txt"
if exist "!TEMP_FILE!" del "!TEMP_FILE!" 2>nul
for %%e in (%SOURCE_EXTS%) do (
    dir /s /b "*%%e" 2>nul >> "!TEMP_FILE!"
)
if not exist "!TEMP_FILE!" (
    call :PRINT_WARN "Î´ÕÒµ½ÈÎºÎÔ´´úÂëÎÄ¼þ"
    call :WAIT_KEY
    goto MENU
)
for /f "delims=" %%f in ('find /c /v "" ^< "!TEMP_FILE!"') do set "FILE_COUNT=%%f"
if !FILE_COUNT!==0 (
    call :PRINT_WARN "Î´ÕÒµ½ÈÎºÎÔ´´úÂëÎÄ¼þ"
    call :WAIT_KEY
    goto MENU
)
call :PRINT_SUCCESS "ÕÒµ½ !FILE_COUNT! ¸öÔ´´úÂëÎÄ¼þ"
echo.
if !COLOR_ENABLED!==1 (
    echo !C_DIM!ÕýÔÚÌí¼ÓÎÄ¼þ...!C_RESET!
) else (
    echo ÕýÔÚÌí¼ÓÎÄ¼þ...
)
set "DISPLAY_COUNT=0"
for /f "delims=" %%i in ('type "!TEMP_FILE!"') do (
    if !DISPLAY_COUNT! lss 20 (
        set /a DISPLAY_COUNT+=1
        echo   !DISPLAY_COUNT!. %%~nxi
    )
    git add "%%~i" 2>nul
    set /a ADD_COUNT+=1
    if !ADD_COUNT!==100 (
        set /a ADD_COUNT=0
        if !COLOR_ENABLED!==1 (
            echo !C_DIM!.!C_RESET!
        ) else (
            echo .
        )
    )
)
del "!TEMP_FILE!" 2>nul
call :PRINT_SUCCESS "ÒÑÌí¼Ó !FILE_COUNT! ¸öÔ´´úÂëÎÄ¼þ"
if exist ".gitignore" (
    git add ".gitignore" 2>nul
    call :PRINT_INFO ".gitignore ÒÑÌí¼Óµ½ÔÝ´æÇø"
)
call :LOG_ACTION "ADD_SOURCE: !FILE_COUNT! files"
call :WAIT_KEY
goto MENU

:GIT_RESET_HARD
call :CHECK_REPO
git log -1 2>nul | findstr . >nul
if errorlevel 1 (
    call :PRINT_WARN "Ã»ÓÐÌá½»¼ÇÂ¼"
    call :WAIT_KEY
    goto MENU
)
call :PRINT_WARN "´Ë²Ù×÷½«¶ªÆúËùÓÐÎ´Ìá½»µÄÐÞ¸Ä"
if !BACKUP_ENABLED!==1 (
    git stash push -m "auto_backup_!CUR_DATE!_!CUR_TIME!" 2>nul
    if errorlevel 1 (
        call :PRINT_WARN "Ã»ÓÐÐèÒª±¸·ÝµÄ¸ü¸Ä"
    ) else (
        call :PRINT_INFO "ÒÑ×Ô¶¯±¸·Ýµ±Ç°¹¤×÷"
    )
) else (
    call :PRINT_WARN "×Ô¶¯±¸·ÝÒÑ¹Ø±Õ£¬ÎÞ·¨»Ö¸´"
)
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!×î½üµÄÌá½»¼ÇÂ¼£º!C_RESET!
) else (
    echo ×î½üµÄÌá½»¼ÇÂ¼£º
)
git log --oneline --decorate -10 2>&1
echo.
set "commit_hash="
if !COLOR_ENABLED!==1 (
    set /p "commit_hash=!C_CYAN!ÇëÊäÈëÒª»ØÍËµ½µÄÌá½» ID£¨Ç°7Î»£©£º!C_RESET!"
) else (
    set /p "commit_hash=ÇëÊäÈëÒª»ØÍËµ½µÄÌá½» ID£¨Ç°7Î»£©£º"
)
if "!commit_hash!"=="" (
    call :PRINT_WARN "²Ù×÷ÒÑÈ¡Ïû"
    call :WAIT_KEY
    goto MENU
)
git cat-file -t "!commit_hash!" 2>nul | findstr "commit" >nul
if errorlevel 1 (
    call :PRINT_ERROR "Ìá½» ID ²»´æÔÚ"
    call :WAIT_KEY
    goto MENU
)
call :CONFIRM_DANGEROUS
call :PRINT_INFO "ÕýÔÚ»ØÍËµ½ !commit_hash!..."
git reset --hard "!commit_hash!" 2>&1
if errorlevel 1 (
    call :PRINT_ERROR "»ØÍËÊ§°Ü"
    call :LOG_ACTION "RESET_FAILED: !commit_hash!"
) else (
    call :PRINT_SUCCESS "ÒÑ»ØÍËµ½ !commit_hash!"
    git log --oneline -5 2>&1
    call :LOG_ACTION "RESET_SUCCESS: !commit_hash!"
)
call :WAIT_KEY
goto MENU

:GIT_AMEND
call :CHECK_REPO
git log -1 2>nul | findstr . >nul
if errorlevel 1 (
    call :PRINT_WARN "Ã»ÓÐÌá½»¼ÇÂ¼"
    call :WAIT_KEY
    goto MENU
)
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!×î½üµÄÌá½»¼ÇÂ¼£º!C_RESET!
) else (
    echo ×î½üµÄÌá½»¼ÇÂ¼£º
)
git log --oneline --decorate -10 2>&1
echo.
set "commit_hash="
if !COLOR_ENABLED!==1 (
    set /p "commit_hash=!C_CYAN!ÇëÊäÈëÒªÐÞ¸ÄµÄÌá½» ID£¨Ç°7Î»£©£º!C_RESET!"
) else (
    set /p "commit_hash=ÇëÊäÈëÒªÐÞ¸ÄµÄÌá½» ID£¨Ç°7Î»£©£º"
)
if "!commit_hash!"=="" (
    call :PRINT_WARN "²Ù×÷ÒÑÈ¡Ïû"
    call :WAIT_KEY
    goto MENU
)
git cat-file -t "!commit_hash!" 2>nul | findstr "commit" >nul
if errorlevel 1 (
    call :PRINT_ERROR "Ìá½» ID ²»´æÔÚ"
    call :WAIT_KEY
    goto MENU
)
for /f "delims=" %%i in ('git log --format=%%s -n 1 "!commit_hash!" 2^>nul') do set "OLD_MSG=%%i"
if !COLOR_ENABLED!==1 (
    echo !C_BLUE!µ±Ç°±¸×¢: !C_RESET!!OLD_MSG!
) else (
    echo µ±Ç°±¸×¢: !OLD_MSG!
)
set "new_msg="
if !COLOR_ENABLED!==1 (
    set /p "new_msg=!C_CYAN!ÇëÊäÈëÐÂ±¸×¢£º!C_RESET!"
) else (
    set /p "new_msg=ÇëÊäÈëÐÂ±¸×¢£º"
)
if "!new_msg!"=="" (
    call :PRINT_WARN "±¸×¢²»ÄÜÎª¿Õ"
    call :WAIT_KEY
    goto MENU
)
for /f "delims=" %%i in ('git rev-parse HEAD 2^>nul') do set "HEAD_HASH=%%i"
if "!HEAD_HASH:~0,7!"=="!commit_hash!" (
    git commit --amend -m "!new_msg!" 2>&1
    if errorlevel 1 (
        call :PRINT_ERROR "ÐÞ¸ÄÊ§°Ü"
    ) else (
        call :PRINT_SUCCESS "ÒÑÐÞ¸ÄÌá½»±¸×¢"
        call :LOG_ACTION "AMEND_SUCCESS: !commit_hash!"
    )
) else (
    call :PRINT_WARN "ÐÞ¸ÄÀúÊ·Ìá½»¿ÉÄÜÖØÐ´ÀúÊ·"
    call :CONFIRM_DANGEROUS
    for /f "delims=" %%i in ('git rev-list --count HEAD 2^>nul') do set "COMMIT_COUNT=%%i"
    if !COMMIT_COUNT! lss 5 (
        set "REBASE_RANGE=HEAD~!COMMIT_COUNT!"
    ) else (
        set "REBASE_RANGE=HEAD~5"
    )
    git rebase -i !REBASE_RANGE! 2>&1
    if errorlevel 1 (
        call :PRINT_ERROR "±ä»ùÊ§°Ü£¬ÇëÊÖ¶¯´¦Àí"
    ) else (
        call :PRINT_SUCCESS "Ìá½»ÒÑÐÞ¸Ä"
        call :LOG_ACTION "AMEND_REBASE: !commit_hash!"
    )
)
call :WAIT_KEY
goto MENU

:GIT_DIFF
call :CHECK_REPO
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!²îÒì²é¿´£º!C_RESET!
    echo !C_CYAN!1!C_RESET!. ¹¤×÷Çø vs ÔÝ´æÇø
    echo !C_CYAN!2!C_RESET!. ÔÝ´æÇø vs HEAD
    echo !C_CYAN!3!C_RESET!. ¹¤×÷Çø vs HEAD
    echo !C_CYAN!4!C_RESET!. Á½¸öÌá½»Ö®¼ä
    echo !C_CYAN!5!C_RESET!. ·ÖÖ§²îÒì
) else (
    echo ²îÒì²é¿´£º
    echo 1. ¹¤×÷Çø vs ÔÝ´æÇø
    echo 2. ÔÝ´æÇø vs HEAD
    echo 3. ¹¤×÷Çø vs HEAD
    echo 4. Á½¸öÌá½»Ö®¼ä
    echo 5. ·ÖÖ§²îÒì
)
set /p "diff_choice=ÇëÑ¡Ôñ [1-5]£º"
if "!diff_choice!"=="1" git diff 2>&1
if "!diff_choice!"=="2" git diff --cached 2>&1
if "!diff_choice!"=="3" git diff HEAD 2>&1
if "!diff_choice!"=="4" (
    git log --oneline -10 2>&1
    if !COLOR_ENABLED!==1 (
        set /p "commit1=!C_CYAN!µÚÒ»¸öÌá½» ID£º!C_RESET!"
        set /p "commit2=!C_CYAN!µÚ¶þ¸öÌá½» ID£º!C_RESET!"
    ) else (
        set /p "commit1=µÚÒ»¸öÌá½» ID£º"
        set /p "commit2=µÚ¶þ¸öÌá½» ID£º"
    )
    git diff "!commit1!" "!commit2!" 2>&1
)
if "!diff_choice!"=="5" (
    git branch 2>&1
    if !COLOR_ENABLED!==1 (
        set /p "branch1=!C_CYAN!µÚÒ»¸ö·ÖÖ§£º!C_RESET!"
        set /p "branch2=!C_CYAN!µÚ¶þ¸ö·ÖÖ§£º!C_RESET!"
    ) else (
        set /p "branch1=µÚÒ»¸ö·ÖÖ§£º"
        set /p "branch2=µÚ¶þ¸ö·ÖÖ§£º"
    )
    git diff "!branch1!" "!branch2!" 2>&1
)
call :WAIT_KEY
goto MENU

:GIT_SHOW
call :CHECK_REPO
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!Ìá½»ÏêÇé²é¿´£º!C_RESET!
) else (
    echo Ìá½»ÏêÇé²é¿´£º
)
git log --oneline -15 2>&1
echo.
set "commit_hash="
if !COLOR_ENABLED!==1 (
    set /p "commit_hash=!C_CYAN!ÇëÊäÈëÌá½» ID£º!C_RESET!"
) else (
    set /p "commit_hash=ÇëÊäÈëÌá½» ID£º"
)
if "!commit_hash!"=="" (
    call :PRINT_WARN "²Ù×÷ÒÑÈ¡Ïû"
    call :WAIT_KEY
    goto MENU
)
git show "!commit_hash!" --stat 2>&1
if !COLOR_ENABLED!==1 (
    echo !C_DIM!°´ÈÎÒâ¼ü²é¿´ÍêÕû²îÒì...!C_RESET!
) else (
    echo °´ÈÎÒâ¼ü²é¿´ÍêÕû²îÒì...
)
pause >nul
git show "!commit_hash!" 2>&1 | more
call :WAIT_KEY
goto MENU

:GIT_BRANCH_CREATE
call :CHECK_REPO
set "branch_name="
if !COLOR_ENABLED!==1 (
    set /p "branch_name=!C_CYAN!ÇëÊäÈëÐÂ·ÖÖ§Ãû³Æ£º!C_RESET!"
) else (
    set /p "branch_name=ÇëÊäÈëÐÂ·ÖÖ§Ãû³Æ£º"
)
if "!branch_name!"=="" (
    call :PRINT_WARN "²Ù×÷ÒÑÈ¡Ïû"
    call :WAIT_KEY
    goto MENU
)
git branch "!branch_name!" 2>&1
if errorlevel 1 (
    call :PRINT_ERROR "´´½¨·ÖÖ§Ê§°Ü"
    call :WAIT_KEY
    goto MENU
)
git switch "!branch_name!" 2>&1
if errorlevel 1 (
    git checkout "!branch_name!" 2>&1
)
if errorlevel 1 (
    call :PRINT_ERROR "ÇÐ»»·ÖÖ§Ê§°Ü"
) else (
    call :PRINT_SUCCESS "ÒÑ´´½¨²¢ÇÐ»»µ½·ÖÖ§: !branch_name!"
    call :LOG_ACTION "BRANCH_CREATE: !branch_name!"
)
call :WAIT_KEY
goto MENU

:GIT_BRANCH_SWITCH
call :CHECK_REPO
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!±¾µØ·ÖÖ§£º!C_RESET!
) else (
    echo ±¾µØ·ÖÖ§£º
)
git branch 2>&1
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!Ô¶³Ì·ÖÖ§£º!C_RESET!
) else (
    echo Ô¶³Ì·ÖÖ§£º
)
git branch -r 2>&1
echo.
set "branch_name="
if !COLOR_ENABLED!==1 (
    set /p "branch_name=!C_CYAN!ÇëÊäÈëÒªÇÐ»»µ½µÄ·ÖÖ§Ãû³Æ£º!C_RESET!"
) else (
    set /p "branch_name=ÇëÊäÈëÒªÇÐ»»µ½µÄ·ÖÖ§Ãû³Æ£º"
)
if "!branch_name!"=="" (
    call :PRINT_WARN "²Ù×÷ÒÑÈ¡Ïû"
    call :WAIT_KEY
    goto MENU
)
git switch "!branch_name!" 2>&1
if errorlevel 1 (
    git checkout "!branch_name!" 2>&1
)
if errorlevel 1 (
    call :PRINT_ERROR "ÇÐ»»·ÖÖ§Ê§°Ü"
) else (
    call :PRINT_SUCCESS "ÒÑÇÐ»»µ½·ÖÖ§: !branch_name!"
    call :LOG_ACTION "BRANCH_SWITCH: !branch_name!"
)
call :WAIT_KEY
goto MENU

:GIT_BRANCH_LIST
call :CHECK_REPO
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!±¾µØ·ÖÖ§£º!C_RESET!
) else (
    echo ±¾µØ·ÖÖ§£º
)
git branch -v 2>&1
echo.
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!Ô¶³Ì·ÖÖ§£º!C_RESET!
) else (
    echo Ô¶³Ì·ÖÖ§£º
)
git branch -r -v 2>&1
echo.
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!ËùÓÐ·ÖÖ§£º!C_RESET!
) else (
    echo ËùÓÐ·ÖÖ§£º
)
git branch -a -v 2>&1
call :WAIT_KEY
goto MENU

:GIT_BRANCH_DELETE
call :CHECK_REPO
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!ÏÖÓÐ·ÖÖ§£º!C_RESET!
) else (
    echo ÏÖÓÐ·ÖÖ§£º
)
git branch 2>&1
echo.
set "branch_name="
if !COLOR_ENABLED!==1 (
    set /p "branch_name=!C_CYAN!ÇëÊäÈëÒªÉ¾³ýµÄ·ÖÖ§Ãû³Æ£º!C_RESET!"
) else (
    set /p "branch_name=ÇëÊäÈëÒªÉ¾³ýµÄ·ÖÖ§Ãû³Æ£º"
)
if "!branch_name!"=="" (
    call :PRINT_WARN "²Ù×÷ÒÑÈ¡Ïû"
    call :WAIT_KEY
    goto MENU
)
for /f "delims=" %%i in ('git branch --show-current 2^>nul') do set "CURRENT_BRANCH=%%i"
if "!branch_name!"=="!CURRENT_BRANCH!" (
    call :PRINT_ERROR "²»ÄÜÉ¾³ýµ±Ç°·ÖÖ§"
    call :WAIT_KEY
    goto MENU
)
if !COLOR_ENABLED!==1 (
    echo !C_YELLOW!1. °²È«É¾³ý£¨ÒÑºÏ²¢£©!C_RESET!
    echo !C_RED!2. Ç¿ÖÆÉ¾³ý£¨Î´ºÏ²¢£©!C_RESET!
) else (
    echo 1. °²È«É¾³ý£¨ÒÑºÏ²¢£©
    echo 2. Ç¿ÖÆÉ¾³ý£¨Î´ºÏ²¢£©
)
set /p "del_choice=ÇëÑ¡Ôñ [1-2]£º"
if "!del_choice!"=="1" (
    git branch -d "!branch_name!" 2>&1
) else if "!del_choice!"=="2" (
    call :CONFIRM_DANGEROUS
    git branch -D "!branch_name!" 2>&1
) else (
    call :PRINT_ERROR "ÎÞÐ§Ñ¡Ïî"
    call :WAIT_KEY
    goto MENU
)
if errorlevel 1 (
    call :PRINT_ERROR "É¾³ý·ÖÖ§Ê§°Ü"
) else (
    call :PRINT_SUCCESS "·ÖÖ§ÒÑÉ¾³ý: !branch_name!"
    call :LOG_ACTION "BRANCH_DELETE: !branch_name!"
)
call :WAIT_KEY
goto MENU

:GIT_BRANCH_MERGE
call :CHECK_REPO
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!µ±Ç°·ÖÖ§£º!C_RESET!
) else (
    echo µ±Ç°·ÖÖ§£º
)
git branch --show-current 2>&1
echo.
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!¿ÉÓÃ·ÖÖ§£º!C_RESET!
) else (
    echo ¿ÉÓÃ·ÖÖ§£º
)
git branch 2>&1
echo.
set "branch_name="
if !COLOR_ENABLED!==1 (
    set /p "branch_name=!C_CYAN!ÇëÊäÈëÒªºÏ²¢µÄ·ÖÖ§£º!C_RESET!"
) else (
    set /p "branch_name=ÇëÊäÈëÒªºÏ²¢µÄ·ÖÖ§£º"
)
if "!branch_name!"=="" (
    call :PRINT_WARN "²Ù×÷ÒÑÈ¡Ïû"
    call :WAIT_KEY
    goto MENU
)
for /f "delims=" %%i in ('git branch --show-current 2^>nul') do set "CURRENT_BRANCH=%%i"
if "!branch_name!"=="!CURRENT_BRANCH!" (
    call :PRINT_WARN "²»ÄÜºÏ²¢×ÔÉí"
    call :WAIT_KEY
    goto MENU
)
call :CONFIRM_ACTION
call :PRINT_INFO "ÕýÔÚºÏ²¢ !branch_name!..."
git merge --no-ff "!branch_name!" 2>&1
if errorlevel 1 (
    call :PRINT_ERROR "ºÏ²¢Ê§°Ü£¬Çë½â¾ö³åÍ»"
    call :PRINT_INFO "½â¾ö³åÍ»ºóÖ´ÐÐ git add . ºÍ git commit"
    call :LOG_ACTION "MERGE_FAILED: !branch_name!"
) else (
    call :PRINT_SUCCESS "ºÏ²¢³É¹¦"
    call :LOG_ACTION "MERGE_SUCCESS: !branch_name!"
)
call :WAIT_KEY
goto MENU

:GIT_PUSH
call :CHECK_REPO
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!Ô¶³Ì²Ö¿â£º!C_RESET!
) else (
    echo Ô¶³Ì²Ö¿â£º
)
git remote -v 2>&1
echo.
set "remote_name="
if !COLOR_ENABLED!==1 (
    set /p "remote_name=!C_CYAN!Ô¶³Ì²Ö¿âÃû£¨Ä¬ÈÏ !DEFAULT_REMOTE!£©£º!C_RESET!"
) else (
    set /p "remote_name=Ô¶³Ì²Ö¿âÃû£¨Ä¬ÈÏ !DEFAULT_REMOTE!£©£º"
)
if "!remote_name!"=="" set "remote_name=!DEFAULT_REMOTE!"
set "branch_name="
if !COLOR_ENABLED!==1 (
    set /p "branch_name=!C_CYAN!·ÖÖ§Ãû£¨Ä¬ÈÏµ±Ç°£©£º!C_RESET!"
) else (
    set /p "branch_name=·ÖÖ§Ãû£¨Ä¬ÈÏµ±Ç°£©£º"
)
if "!branch_name!"=="" (
    for /f "delims=" %%i in ('git branch --show-current 2^>nul') do set "branch_name=%%i"
)
call :CONFIRM_ACTION
call :PRINT_INFO "ÕýÔÚÍÆËÍµ½ !remote_name!/!branch_name!..."
git push -u "!remote_name!" "!branch_name!" 2>&1
if errorlevel 1 (
    call :PRINT_ERROR "ÍÆËÍÊ§°Ü£¬ÇëÏÈÀ­È¡¸üÐÂ"
    call :LOG_ACTION "PUSH_FAILED"
) else (
    call :PRINT_SUCCESS "ÍÆËÍ³É¹¦"
    call :LOG_ACTION "PUSH_SUCCESS: !remote_name!/!branch_name!"
)
call :WAIT_KEY
goto MENU

:GIT_PULL
call :CHECK_REPO
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!Ô¶³Ì²Ö¿â£º!C_RESET!
) else (
    echo Ô¶³Ì²Ö¿â£º
)
git remote -v 2>&1
echo.
set "remote_name="
if !COLOR_ENABLED!==1 (
    set /p "remote_name=!C_CYAN!Ô¶³Ì²Ö¿âÃû£¨Ä¬ÈÏ !DEFAULT_REMOTE!£©£º!C_RESET!"
) else (
    set /p "remote_name=Ô¶³Ì²Ö¿âÃû£¨Ä¬ÈÏ !DEFAULT_REMOTE!£©£º"
)
if "!remote_name!"=="" set "remote_name=!DEFAULT_REMOTE!"
set "branch_name="
if !COLOR_ENABLED!==1 (
    set /p "branch_name=!C_CYAN!·ÖÖ§Ãû£¨Ä¬ÈÏµ±Ç°£©£º!C_RESET!"
) else (
    set /p "branch_name=·ÖÖ§Ãû£¨Ä¬ÈÏµ±Ç°£©£º"
)
if "!branch_name!"=="" (
    for /f "delims=" %%i in ('git branch --show-current 2^>nul') do set "branch_name=%%i"
)
call :PRINT_INFO "ÕýÔÚÀ­È¡ !remote_name!/!branch_name!..."
git pull --rebase "!remote_name!" "!branch_name!" 2>&1
if errorlevel 1 (
    call :PRINT_ERROR "À­È¡Ê§°Ü£¬Çë½â¾ö³åÍ»"
    call :LOG_ACTION "PULL_FAILED"
) else (
    call :PRINT_SUCCESS "À­È¡³É¹¦"
    call :LOG_ACTION "PULL_SUCCESS: !remote_name!/!branch_name!"
)
call :WAIT_KEY
goto MENU

:GIT_CLONE
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!µ±Ç°Â·¾¶£º!C_RESET!!CURRENT_DIR!
) else (
    echo µ±Ç°Â·¾¶£º!CURRENT_DIR!
)
set "repo_url="
if !COLOR_ENABLED!==1 (
    set /p "repo_url=!C_CYAN!Ô¶³Ì²Ö¿â URL£º!C_RESET!"
) else (
    set /p "repo_url=Ô¶³Ì²Ö¿â URL£º"
)
if "!repo_url!"=="" (
    call :PRINT_WARN "²Ù×÷ÒÑÈ¡Ïû"
    call :WAIT_KEY
    goto MENU
)
set "folder_name="
if !COLOR_ENABLED!==1 (
    set /p "folder_name=!C_CYAN!Ä¿±êÎÄ¼þ¼ÐÃû£¨»Ø³µ×Ô¶¯£©£º!C_RESET!"
) else (
    set /p "folder_name=Ä¿±êÎÄ¼þ¼ÐÃû£¨»Ø³µ×Ô¶¯£©£º"
)
if "!folder_name!"=="" (
    set "folder_name=!repo_url:.git=!"
    for /f "delims=/" %%a in ("!folder_name!") do set "folder_name=%%a"
)
call :PRINT_INFO "ÕýÔÚ¿ËÂ¡²Ö¿â..."
git clone --progress "!repo_url!" "!folder_name!" 2>&1
if errorlevel 1 (
    call :PRINT_ERROR "¿ËÂ¡Ê§°Ü"
    call :LOG_ACTION "CLONE_FAILED: !repo_url!"
) else (
    call :PRINT_SUCCESS "¿ËÂ¡³É¹¦"
    cd /d "!folder_name!" 2>nul
    set "CURRENT_DIR=!cd!"
    call :LOG_ACTION "CLONE_SUCCESS: !repo_url!"
)
call :WAIT_KEY
goto MENU

:GIT_REMOTE_ADD
call :CHECK_REPO
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!µ±Ç°Ô¶³Ì²Ö¿â£º!C_RESET!
) else (
    echo µ±Ç°Ô¶³Ì²Ö¿â£º
)
git remote -v 2>&1
echo.
set "remote_name="
if !COLOR_ENABLED!==1 (
    set /p "remote_name=!C_CYAN!Ô¶³Ì²Ö¿âÃû³Æ£º!C_RESET!"
) else (
    set /p "remote_name=Ô¶³Ì²Ö¿âÃû³Æ£º"
)
if "!remote_name!"=="" (
    call :PRINT_WARN "²Ù×÷ÒÑÈ¡Ïû"
    call :WAIT_KEY
    goto MENU
)
set "remote_url="
if !COLOR_ENABLED!==1 (
    set /p "remote_url=!C_CYAN!Ô¶³Ì²Ö¿â URL£º!C_RESET!"
) else (
    set /p "remote_url=Ô¶³Ì²Ö¿â URL£º"
)
if "!remote_url!"=="" (
    call :PRINT_WARN "²Ù×÷ÒÑÈ¡Ïû"
    call :WAIT_KEY
    goto MENU
)
git remote add "!remote_name!" "!remote_url!" 2>&1
if errorlevel 1 (
    call :PRINT_ERROR "Ìí¼ÓÊ§°Ü£¬¿ÉÄÜÒÑ´æÔÚÍ¬ÃûÔ¶³Ì"
) else (
    call :PRINT_SUCCESS "Ô¶³Ì²Ö¿âÒÑÌí¼Ó: !remote_name!"
    call :LOG_ACTION "REMOTE_ADD: !remote_name!"
)
call :WAIT_KEY
goto MENU

:GIT_REMOTE_LIST
call :CHECK_REPO
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!Ô¶³Ì²Ö¿âÁÐ±í£º!C_RESET!
) else (
    echo Ô¶³Ì²Ö¿âÁÐ±í£º
)
git remote -v 2>&1
echo.
set "REMOTE_COUNT=0"
for /f "delims=" %%i in ('git remote') do (
    set /a REMOTE_COUNT+=1
    echo.
    if !COLOR_ENABLED!==1 (
        echo !C_CYAN![%%i]!C_RESET!
    ) else (
        echo [%%i]
    )
    git remote show %%i 2>&1
)
if !REMOTE_COUNT!==0 (
    call :PRINT_WARN "Ã»ÓÐÅäÖÃÔ¶³Ì²Ö¿â"
)
call :WAIT_KEY
goto MENU

:GIT_REMOTE_REMOVE
call :CHECK_REPO
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!µ±Ç°Ô¶³Ì²Ö¿â£º!C_RESET!
) else (
    echo µ±Ç°Ô¶³Ì²Ö¿â£º
)
git remote -v 2>&1
echo.
set "remote_name="
if !COLOR_ENABLED!==1 (
    set /p "remote_name=!C_CYAN!ÒªÉ¾³ýµÄÔ¶³Ì²Ö¿âÃû£º!C_RESET!"
) else (
    set /p "remote_name=ÒªÉ¾³ýµÄÔ¶³Ì²Ö¿âÃû£º"
)
if "!remote_name!"=="" (
    call :PRINT_WARN "²Ù×÷ÒÑÈ¡Ïû"
    call :WAIT_KEY
    goto MENU
)
call :CONFIRM_DANGEROUS
git remote remove "!remote_name!" 2>&1
if errorlevel 1 (
    call :PRINT_ERROR "É¾³ýÊ§°Ü"
) else (
    call :PRINT_SUCCESS "Ô¶³Ì²Ö¿âÒÑÉ¾³ý: !remote_name!"
    call :LOG_ACTION "REMOTE_REMOVE: !remote_name!"
)
call :WAIT_KEY
goto MENU

:GIT_STASH_PUSH
call :CHECK_REPO
set "stash_msg="
if !COLOR_ENABLED!==1 (
    set /p "stash_msg=!C_CYAN!ÔÝ´æËµÃ÷£¨»Ø³µÊ¹ÓÃÄ¬ÈÏ£©£º!C_RESET!"
) else (
    set /p "stash_msg=ÔÝ´æËµÃ÷£¨»Ø³µÊ¹ÓÃÄ¬ÈÏ£©£º"
)
if "!stash_msg!"=="" set "stash_msg=stash !date! !time!"
git stash push -m "!stash_msg!" 2>&1
if errorlevel 1 (
    call :PRINT_ERROR "ÔÝ´æÊ§°Ü"
) else (
    call :PRINT_SUCCESS "¹¤×÷ÒÑÔÝ´æ"
    call :LOG_ACTION "STASH_PUSH: !stash_msg!"
)
call :WAIT_KEY
goto MENU

:GIT_STASH_POP
call :CHECK_REPO
git stash list 2>&1 | findstr . >nul
if errorlevel 1 (
    call :PRINT_WARN "Ã»ÓÐÔÝ´æµÄ¹¤×÷"
    call :WAIT_KEY
    goto MENU
)
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!ÔÝ´æÁÐ±í£º!C_RESET!
) else (
    echo ÔÝ´æÁÐ±í£º
)
git stash list 2>&1
echo.
if !COLOR_ENABLED!==1 (
    echo !C_YELLOW!1. »Ö¸´×îÐÂ²¢É¾³ý!C_RESET!
    echo !C_YELLOW!2. »Ö¸´×îÐÂ±£Áô!C_RESET!
    echo !C_YELLOW!3. Ñ¡ÔñÖ¸¶¨ÔÝ´æ!C_RESET!
) else (
    echo 1. »Ö¸´×îÐÂ²¢É¾³ý
    echo 2. »Ö¸´×îÐÂ±£Áô
    echo 3. Ñ¡ÔñÖ¸¶¨ÔÝ´æ
)
set /p "pop_choice=ÇëÑ¡Ôñ [1-3]£º"
if "!pop_choice!"=="1" (
    git stash pop 2>&1
) else if "!pop_choice!"=="2" (
    git stash apply 2>&1
) else if "!pop_choice!"=="3" (
    set "stash_index="
    if !COLOR_ENABLED!==1 (
        set /p "stash_index=!C_CYAN!ÔÝ´æË÷Òý£¨ÊäÈëÊý×Ö£¬Èç 0£©£º!C_RESET!"
    ) else (
        set /p "stash_index=ÔÝ´æË÷Òý£¨ÊäÈëÊý×Ö£¬Èç 0£©£º"
    )
    if "!stash_index!"=="" (
        call :PRINT_WARN "²Ù×÷ÒÑÈ¡Ïû"
        call :WAIT_KEY
        goto MENU
    )
    git stash pop stash@^^{!stash_index!^} 2>&1
) else (
    call :PRINT_ERROR "ÎÞÐ§Ñ¡Ïî"
    call :WAIT_KEY
    goto MENU
)
if errorlevel 1 (
    call :PRINT_ERROR "»Ö¸´Ê§°Ü£¬¿ÉÄÜÓÐ³åÍ»"
) else (
    call :PRINT_SUCCESS "¹¤×÷ÒÑ»Ö¸´"
    call :LOG_ACTION "STASH_POP"
)
call :WAIT_KEY
goto MENU

:GIT_STASH_LIST
call :CHECK_REPO
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!ÔÝ´æÁÐ±í£º!C_RESET!
) else (
    echo ÔÝ´æÁÐ±í£º
)
git stash list 2>&1
echo.
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!ÔÝ´æÏêÇé£º!C_RESET!
) else (
    echo ÔÝ´æÏêÇé£º
)
git stash show -p 2>&1 | more
call :WAIT_KEY
goto MENU

:GIT_STASH_DROP
call :CHECK_REPO
git stash list 2>&1 | findstr . >nul
if errorlevel 1 (
    call :PRINT_WARN "Ã»ÓÐÔÝ´æµÄ¹¤×÷"
    call :WAIT_KEY
    goto MENU
)
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!ÔÝ´æÁÐ±í£º!C_RESET!
) else (
    echo ÔÝ´æÁÐ±í£º
)
git stash list 2>&1
echo.
set "stash_index="
if !COLOR_ENABLED!==1 (
    set /p "stash_index=!C_CYAN!ÒªÉ¾³ýµÄÔÝ´æË÷Òý£¨ÊäÈëÊý×Ö£¬Áô¿ÕÉ¾³ý×îÐÂ£©£º!C_RESET!"
) else (
    set /p "stash_index=ÒªÉ¾³ýµÄÔÝ´æË÷Òý£¨ÊäÈëÊý×Ö£¬Áô¿ÕÉ¾³ý×îÐÂ£©£º"
)
call :CONFIRM_ACTION
if "!stash_index!"=="" (
    git stash drop 2>&1
) else (
    git stash drop stash@^^{!stash_index!^} 2>&1
)
if errorlevel 1 (
    call :PRINT_ERROR "É¾³ýÊ§°Ü"
) else (
    call :PRINT_SUCCESS "ÔÝ´æÒÑÉ¾³ý"
    call :LOG_ACTION "STASH_DROP"
)
call :WAIT_KEY
goto MENU

:GIT_CLEAN
call :CHECK_REPO
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!Î´¸ú×ÙÎÄ¼þ£º!C_RESET!
) else (
    echo Î´¸ú×ÙÎÄ¼þ£º
)
git ls-files --others --exclude-standard 2>&1
echo.
if !COLOR_ENABLED!==1 (
    echo !C_YELLOW!1. Ô¤ÀÀ£¨½öÏÔÊ¾£©!C_RESET!
    echo !C_YELLOW!2. É¾³ýÎ´¸ú×ÙÎÄ¼þ!C_RESET!
    echo !C_YELLOW!3. É¾³ýËùÓÐÎ´¸ú×Ù£¨º¬ºöÂÔ£©!C_RESET!
    echo !C_YELLOW!4. É¾³ýÎ´¸ú×ÙÄ¿Â¼!C_RESET!
) else (
    echo 1. Ô¤ÀÀ£¨½öÏÔÊ¾£©
    echo 2. É¾³ýÎ´¸ú×ÙÎÄ¼þ
    echo 3. É¾³ýËùÓÐÎ´¸ú×Ù£¨º¬ºöÂÔ£©
    echo 4. É¾³ýÎ´¸ú×ÙÄ¿Â¼
)
set /p "clean_choice=ÇëÑ¡Ôñ [1-4]£º"
if "!clean_choice!"=="1" git clean -n 2>&1
if "!clean_choice!"=="2" (
    call :CONFIRM_ACTION
    git clean -f 2>&1
    call :LOG_ACTION "CLEAN_FILES"
)
if "!clean_choice!"=="3" (
    call :CONFIRM_DANGEROUS
    git clean -fx 2>&1
    call :LOG_ACTION "CLEAN_ALL"
)
if "!clean_choice!"=="4" (
    call :CONFIRM_DANGEROUS
    git clean -fd 2>&1
    call :LOG_ACTION "CLEAN_DIRS"
)
call :WAIT_KEY
goto MENU

:GIT_RESTORE
call :CHECK_REPO
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!ÐÞ¸ÄµÄÎÄ¼þ£º!C_RESET!
) else (
    echo ÐÞ¸ÄµÄÎÄ¼þ£º
)
git status --porcelain 2>&1
echo.
if !COLOR_ENABLED!==1 (
    echo !C_YELLOW!1. ³·Ïúµ¥¸öÎÄ¼þ!C_RESET!
    echo !C_YELLOW!2. ³·ÏúËùÓÐÐÞ¸Ä!C_RESET!
    echo !C_YELLOW!3. ³·ÏúËùÓÐÐÞ¸Ä£¨º¬ÐÂÔö£©!C_RESET!
) else (
    echo 1. ³·Ïúµ¥¸öÎÄ¼þ
    echo 2. ³·ÏúËùÓÐÐÞ¸Ä
    echo 3. ³·ÏúËùÓÐÐÞ¸Ä£¨º¬ÐÂÔö£©
)
set /p "restore_choice=ÇëÑ¡Ôñ [1-3]£º"
if "!restore_choice!"=="1" (
    set "file_path="
    if !COLOR_ENABLED!==1 (
        set /p "file_path=!C_CYAN!ÎÄ¼þÂ·¾¶£º!C_RESET!"
    ) else (
        set /p "file_path=ÎÄ¼þÂ·¾¶£º"
    )
    if "!file_path!"=="" (
        call :PRINT_WARN "²Ù×÷ÒÑÈ¡Ïû"
    ) else (
        git restore "!file_path!" 2>&1
        if errorlevel 1 (
            git checkout -- "!file_path!" 2>&1
        )
        if errorlevel 1 (
            call :PRINT_ERROR "³·ÏúÊ§°Ü"
        ) else (
            call :PRINT_SUCCESS "ÒÑ³·Ïú: !file_path!"
        )
    )
)
if "!restore_choice!"=="2" (
    call :CONFIRM_ACTION
    git restore . 2>&1
    if errorlevel 1 (
        git checkout -- . 2>&1
    )
    call :PRINT_SUCCESS "ÒÑ³·ÏúËùÓÐÐÞ¸Ä"
    call :LOG_ACTION "RESTORE_ALL"
)
if "!restore_choice!"=="3" (
    call :CONFIRM_DANGEROUS
    git clean -fd 2>&1
    git restore . 2>&1
    if errorlevel 1 (
        git checkout -- . 2>&1
    )
    call :PRINT_SUCCESS "ÒÑ³·ÏúËùÓÐÐÞ¸Ä"
    call :LOG_ACTION "RESTORE_ALL_INCL_NEW"
)
call :WAIT_KEY
goto MENU

:GIT_CONFIG
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!Git ÅäÖÃ¹ÜÀí£º!C_RESET!
    echo !C_CYAN!1!C_RESET!. ÉèÖÃÓÃ»§Ãû
    echo !C_CYAN!2!C_RESET!. ÉèÖÃÓÊÏä
    echo !C_CYAN!3!C_RESET!. ÉèÖÃÄ¬ÈÏ±à¼­Æ÷
    echo !C_CYAN!4!C_RESET!. ²é¿´È«¾ÖÅäÖÃ
    echo !C_CYAN!5!C_RESET!. ²é¿´±¾µØÅäÖÃ
    echo !C_CYAN!6!C_RESET!. ÖØÖÃÅäÖÃ
) else (
    echo Git ÅäÖÃ¹ÜÀí£º
    echo 1. ÉèÖÃÓÃ»§Ãû
    echo 2. ÉèÖÃÓÊÏä
    echo 3. ÉèÖÃÄ¬ÈÏ±à¼­Æ÷
    echo 4. ²é¿´È«¾ÖÅäÖÃ
    echo 5. ²é¿´±¾µØÅäÖÃ
    echo 6. ÖØÖÃÅäÖÃ
)
set /p "cfg_choice=ÇëÑ¡Ôñ [1-6]£º"
if "!cfg_choice!"=="1" (
    set "git_user="
    if !COLOR_ENABLED!==1 (
        set /p "git_user=!C_CYAN!ÓÃ»§Ãû£º!C_RESET!"
    ) else (
        set /p "git_user=ÓÃ»§Ãû£º"
    )
    if not "!git_user!"=="" (
        git config --global user.name "!git_user!"
        call :PRINT_SUCCESS "ÓÃ»§ÃûÒÑÉèÖÃ"
        call :LOG_ACTION "CONFIG_USER: !git_user!"
    )
)
if "!cfg_choice!"=="2" (
    set "git_mail="
    if !COLOR_ENABLED!==1 (
        set /p "git_mail=!C_CYAN!ÓÊÏä£º!C_RESET!"
    ) else (
        set /p "git_mail=ÓÊÏä£º"
    )
    if not "!git_mail!"=="" (
        git config --global user.email "!git_mail!"
        call :PRINT_SUCCESS "ÓÊÏäÒÑÉèÖÃ"
        call :LOG_ACTION "CONFIG_EMAIL: !git_mail!"
    )
)
if "!cfg_choice!"=="3" (
    set "git_editor="
    if !COLOR_ENABLED!==1 (
        set /p "git_editor=!C_CYAN!±à¼­Æ÷ÃüÁî£¨Èç vim, code£©£º!C_RESET!"
    ) else (
        set /p "git_editor=±à¼­Æ÷ÃüÁî£¨Èç vim, code£©£º"
    )
    if not "!git_editor!"=="" (
        git config --global core.editor "!git_editor!"
        call :PRINT_SUCCESS "±à¼­Æ÷ÒÑÉèÖÃ"
    )
)
if "!cfg_choice!"=="4" git config --global --list
if "!cfg_choice!"=="5" git config --local --list
if "!cfg_choice!"=="6" (
    call :CONFIRM_DANGEROUS
    git config --global --unset-all user.name 2>nul
    git config --global --unset-all user.email 2>nul
    call :PRINT_SUCCESS "ÅäÖÃÒÑÖØÖÃ"
)
call :WAIT_KEY
goto MENU

:GIT_ABORT
call :CHECK_REPO
git merge --abort 2>nul
git rebase --abort 2>nul
git cherry-pick --abort 2>nul
call :PRINT_SUCCESS "ÒÑ·ÅÆúËùÓÐ³åÍ»²Ù×÷"
call :LOG_ACTION "ABORT_CONFLICT"
call :WAIT_KEY
goto MENU

:GIT_REBASE
call :CHECK_REPO
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!½»»¥Ê½±ä»ù£º!C_RESET!
) else (
    echo ½»»¥Ê½±ä»ù£º
)
git log --oneline -10 2>&1
echo.
set "base_commit="
if !COLOR_ENABLED!==1 (
    set /p "base_commit=!C_CYAN!»ùÓÚÄÄ¸öÌá½»¿ªÊ¼±ä»ù£¨Ç°7Î»£©£º!C_RESET!"
) else (
    set /p "base_commit=»ùÓÚÄÄ¸öÌá½»¿ªÊ¼±ä»ù£¨Ç°7Î»£©£º"
)
if "!base_commit!"=="" (
    call :PRINT_WARN "²Ù×÷ÒÑÈ¡Ïû"
    call :WAIT_KEY
    goto MENU
)
call :CONFIRM_ACTION
call :PRINT_INFO "ÕýÔÚÆô¶¯½»»¥Ê½±ä»ù..."
git rebase -i "!base_commit!" 2>&1
if errorlevel 1 (
    call :PRINT_ERROR "±ä»ùÊ§°Ü£¬Çë½â¾ö³åÍ»»òÖ´ÐÐ [33] ·ÅÆú"
    call :LOG_ACTION "REBASE_FAILED"
) else (
    call :PRINT_SUCCESS "±ä»ù³É¹¦"
    call :LOG_ACTION "REBASE_SUCCESS"
)
call :WAIT_KEY
goto MENU

:GIT_TAG
call :CHECK_REPO
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!±êÇ©¹ÜÀí£º!C_RESET!
    echo !C_CYAN!1!C_RESET!. ²é¿´±êÇ©
    echo !C_CYAN!2!C_RESET!. ´´½¨±êÇ©
    echo !C_CYAN!3!C_RESET!. É¾³ý±êÇ©
    echo !C_CYAN!4!C_RESET!. ÍÆËÍ±êÇ©µ½Ô¶³Ì
) else (
    echo ±êÇ©¹ÜÀí£º
    echo 1. ²é¿´±êÇ©
    echo 2. ´´½¨±êÇ©
    echo 3. É¾³ý±êÇ©
    echo 4. ÍÆËÍ±êÇ©µ½Ô¶³Ì
)
set /p "tag_choice=ÇëÑ¡Ôñ [1-4]£º"
if "!tag_choice!"=="1" git tag -l 2>&1
if "!tag_choice!"=="2" (
    set "tag_name="
    if !COLOR_ENABLED!==1 (
        set /p "tag_name=!C_CYAN!±êÇ©Ãû³Æ£º!C_RESET!"
    ) else (
        set /p "tag_name=±êÇ©Ãû³Æ£º"
    )
    if "!tag_name!"=="" (
        call :PRINT_WARN "²Ù×÷ÒÑÈ¡Ïû"
        call :WAIT_KEY
        goto MENU
    )
    set "tag_msg="
    if !COLOR_ENABLED!==1 (
        set /p "tag_msg=!C_CYAN!±êÇ©ËµÃ÷£º!C_RESET!"
    ) else (
        set /p "tag_msg=±êÇ©ËµÃ÷£º"
    )
    git tag -a "!tag_name!" -m "!tag_msg!" 2>&1
    if errorlevel 1 (
        call :PRINT_ERROR "´´½¨±êÇ©Ê§°Ü"
    ) else (
        call :PRINT_SUCCESS "±êÇ©ÒÑ´´½¨: !tag_name!"
        call :LOG_ACTION "TAG_CREATE: !tag_name!"
    )
)
if "!tag_choice!"=="3" (
    set "tag_name="
    if !COLOR_ENABLED!==1 (
        set /p "tag_name=!C_CYAN!ÒªÉ¾³ýµÄ±êÇ©£º!C_RESET!"
    ) else (
        set /p "tag_name=ÒªÉ¾³ýµÄ±êÇ©£º"
    )
    if "!tag_name!"=="" (
        call :PRINT_WARN "²Ù×÷ÒÑÈ¡Ïû"
        call :WAIT_KEY
        goto MENU
    )
    call :CONFIRM_ACTION
    git tag -d "!tag_name!" 2>&1
    if errorlevel 1 (
        call :PRINT_ERROR "É¾³ýÊ§°Ü"
    ) else (
        call :PRINT_SUCCESS "±êÇ©ÒÑÉ¾³ý"
        call :LOG_ACTION "TAG_DELETE: !tag_name!"
    )
)
if "!tag_choice!"=="4" (
    set "tag_name="
    if !COLOR_ENABLED!==1 (
        set /p "tag_name=!C_CYAN!ÒªÍÆËÍµÄ±êÇ©£¨Áô¿ÕÍÆËÍÈ«²¿£©£º!C_RESET!"
    ) else (
        set /p "tag_name=ÒªÍÆËÍµÄ±êÇ©£¨Áô¿ÕÍÆËÍÈ«²¿£©£º"
    )
    if "!tag_name!"=="" (
        git push --tags 2>&1
    ) else (
        git push origin "!tag_name!" 2>&1
    )
    if errorlevel 1 (
        call :PRINT_ERROR "ÍÆËÍÊ§°Ü"
    ) else (
        call :PRINT_SUCCESS "±êÇ©ÒÑÍÆËÍ"
        call :LOG_ACTION "TAG_PUSH: !tag_name!"
    )
)
call :WAIT_KEY
goto MENU

:GIT_SUBMODULE
call :CHECK_REPO
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!×ÓÄ£¿é¹ÜÀí£º!C_RESET!
    echo !C_CYAN!1!C_RESET!. ²é¿´×ÓÄ£¿é
    echo !C_CYAN!2!C_RESET!. Ìí¼Ó×ÓÄ£¿é
    echo !C_CYAN!3!C_RESET!. ¸üÐÂ×ÓÄ£¿é
    echo !C_CYAN!4!C_RESET!. ³õÊ¼»¯×ÓÄ£¿é
) else (
    echo ×ÓÄ£¿é¹ÜÀí£º
    echo 1. ²é¿´×ÓÄ£¿é
    echo 2. Ìí¼Ó×ÓÄ£¿é
    echo 3. ¸üÐÂ×ÓÄ£¿é
    echo 4. ³õÊ¼»¯×ÓÄ£¿é
)
set /p "sub_choice=ÇëÑ¡Ôñ [1-4]£º"
if "!sub_choice!"=="1" git submodule status 2>&1
if "!sub_choice!"=="2" (
    set "sub_url="
    if !COLOR_ENABLED!==1 (
        set /p "sub_url=!C_CYAN!×ÓÄ£¿é URL£º!C_RESET!"
    ) else (
        set /p "sub_url=×ÓÄ£¿é URL£º"
    )
    if "!sub_url!"=="" (
        call :PRINT_WARN "²Ù×÷ÒÑÈ¡Ïû"
        call :WAIT_KEY
        goto MENU
    )
    set "sub_path="
    if !COLOR_ENABLED!==1 (
        set /p "sub_path=!C_CYAN!±¾µØÂ·¾¶£º!C_RESET!"
    ) else (
        set /p "sub_path=±¾µØÂ·¾¶£º"
    )
    if "!sub_path!"=="" (
        call :PRINT_WARN "²Ù×÷ÒÑÈ¡Ïû"
        call :WAIT_KEY
        goto MENU
    )
    git submodule add "!sub_url!" "!sub_path!" 2>&1
    if errorlevel 1 (
        call :PRINT_ERROR "Ìí¼ÓÊ§°Ü"
    ) else (
        call :PRINT_SUCCESS "×ÓÄ£¿éÒÑÌí¼Ó"
        call :LOG_ACTION "SUBMODULE_ADD: !sub_url!"
    )
)
if "!sub_choice!"=="3" git submodule update --remote 2>&1
if "!sub_choice!"=="4" git submodule init 2>&1
call :WAIT_KEY
goto MENU

:GIT_CHERRY_PICK
call :CHECK_REPO
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!¼ðÑ¡Ìá½»£º!C_RESET!
) else (
    echo ¼ðÑ¡Ìá½»£º
)
git log --oneline -15 2>&1
echo.
set "commit_hash="
if !COLOR_ENABLED!==1 (
    set /p "commit_hash=!C_CYAN!Òª¼ðÑ¡µÄÌá½» ID£º!C_RESET!"
) else (
    set /p "commit_hash=Òª¼ðÑ¡µÄÌá½» ID£º"
)
if "!commit_hash!"=="" (
    call :PRINT_WARN "²Ù×÷ÒÑÈ¡Ïû"
    call :WAIT_KEY
    goto MENU
)
call :CONFIRM_ACTION
git cherry-pick "!commit_hash!" 2>&1
if errorlevel 1 (
    call :PRINT_ERROR "¼ðÑ¡Ê§°Ü£¬Çë½â¾ö³åÍ»"
    call :LOG_ACTION "CHERRY_PICK_FAILED: !commit_hash!"
) else (
    call :PRINT_SUCCESS "¼ðÑ¡³É¹¦"
    call :LOG_ACTION "CHERRY_PICK_SUCCESS: !commit_hash!"
)
call :WAIT_KEY
goto MENU

:GIT_BISECT
call :CHECK_REPO
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!¶þ·Ö²éÕÒ£º!C_RESET!
    echo !C_CYAN!1!C_RESET!. ¿ªÊ¼¶þ·Ö²éÕÒ
    echo !C_CYAN!2!C_RESET!. ±ê¼ÇÎª»µÌá½»
    echo !C_CYAN!3!C_RESET!. ±ê¼ÇÎªºÃÌá½»
    echo !C_CYAN!4!C_RESET!. ÖØÖÃ¶þ·Ö²éÕÒ
) else (
    echo ¶þ·Ö²éÕÒ£º
    echo 1. ¿ªÊ¼¶þ·Ö²éÕÒ
    echo 2. ±ê¼ÇÎª»µÌá½»
    echo 3. ±ê¼ÇÎªºÃÌá½»
    echo 4. ÖØÖÃ¶þ·Ö²éÕÒ
)
set /p "bisect_choice=ÇëÑ¡Ôñ [1-4]£º"
if "!bisect_choice!"=="1" (
    set "bad_commit="
    if !COLOR_ENABLED!==1 (
        set /p "bad_commit=!C_CYAN!»µÌá½» ID£º!C_RESET!"
    ) else (
        set /p "bad_commit=»µÌá½» ID£º"
    )
    if "!bad_commit!"=="" (
        call :PRINT_WARN "²Ù×÷ÒÑÈ¡Ïû"
        call :WAIT_KEY
        goto MENU
    )
    set "good_commit="
    if !COLOR_ENABLED!==1 (
        set /p "good_commit=!C_CYAN!ºÃÌá½» ID£º!C_RESET!"
    ) else (
        set /p "good_commit=ºÃÌá½» ID£º"
    )
    if "!good_commit!"=="" (
        call :PRINT_WARN "²Ù×÷ÒÑÈ¡Ïû"
        call :WAIT_KEY
        goto MENU
    )
    git bisect start "!bad_commit!" "!good_commit!" 2>&1
    call :PRINT_INFO "¶þ·Ö²éÕÒÒÑ¿ªÊ¼£¬²âÊÔºó±ê¼ÇºÃ»µ"
)
if "!bisect_choice!"=="2" (
    git bisect bad 2>&1
    call :PRINT_INFO "ÒÑ±ê¼ÇÎª»µÌá½»"
)
if "!bisect_choice!"=="3" (
    git bisect good 2>&1
    call :PRINT_INFO "ÒÑ±ê¼ÇÎªºÃÌá½»"
)
if "!bisect_choice!"=="4" (
    git bisect reset 2>&1
    call :PRINT_SUCCESS "¶þ·Ö²éÕÒÒÑÖØÖÃ"
)
call :WAIT_KEY
goto MENU

:GIT_WORKTREE
call :CHECK_REPO
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!¹¤×÷Ê÷¹ÜÀí£º!C_RESET!
    echo !C_CYAN!1!C_RESET!. ²é¿´¹¤×÷Ê÷ÁÐ±í
    echo !C_CYAN!2!C_RESET!. Ìí¼Ó¹¤×÷Ê÷
    echo !C_CYAN!3!C_RESET!. É¾³ý¹¤×÷Ê÷
) else (
    echo ¹¤×÷Ê÷¹ÜÀí£º
    echo 1. ²é¿´¹¤×÷Ê÷ÁÐ±í
    echo 2. Ìí¼Ó¹¤×÷Ê÷
    echo 3. É¾³ý¹¤×÷Ê÷
)
set /p "worktree_choice=ÇëÑ¡Ôñ [1-3]£º"
if "!worktree_choice!"=="1" git worktree list 2>&1
if "!worktree_choice!"=="2" (
    set "worktree_path="
    if !COLOR_ENABLED!==1 (
        set /p "worktree_path=!C_CYAN!¹¤×÷Ê÷Â·¾¶£º!C_RESET!"
    ) else (
        set /p "worktree_path=¹¤×÷Ê÷Â·¾¶£º"
    )
    if "!worktree_path!"=="" (
        call :PRINT_WARN "²Ù×÷ÒÑÈ¡Ïû"
        call :WAIT_KEY
        goto MENU
    )
    set "worktree_branch="
    if !COLOR_ENABLED!==1 (
        set /p "worktree_branch=!C_CYAN!·ÖÖ§Ãû³Æ£º!C_RESET!"
    ) else (
        set /p "worktree_branch=·ÖÖ§Ãû³Æ£º"
    )
    if "!worktree_branch!"=="" (
        call :PRINT_WARN "²Ù×÷ÒÑÈ¡Ïû"
        call :WAIT_KEY
        goto MENU
    )
    git worktree add "!worktree_path!" "!worktree_branch!" 2>&1
    if errorlevel 1 (
        call :PRINT_ERROR "Ìí¼ÓÊ§°Ü"
    ) else (
        call :PRINT_SUCCESS "¹¤×÷Ê÷ÒÑÌí¼Ó"
        call :LOG_ACTION "WORKTREE_ADD: !worktree_path!"
    )
)
if "!worktree_choice!"=="3" (
    set "worktree_path="
    if !COLOR_ENABLED!==1 (
        set /p "worktree_path=!C_CYAN!ÒªÉ¾³ýµÄ¹¤×÷Ê÷Â·¾¶£º!C_RESET!"
    ) else (
        set /p "worktree_path=ÒªÉ¾³ýµÄ¹¤×÷Ê÷Â·¾¶£º"
    )
    if "!worktree_path!"=="" (
        call :PRINT_WARN "²Ù×÷ÒÑÈ¡Ïû"
        call :WAIT_KEY
        goto MENU
    )
    call :CONFIRM_ACTION
    git worktree remove "!worktree_path!" 2>&1
    if errorlevel 1 (
        call :PRINT_ERROR "É¾³ýÊ§°Ü"
    ) else (
        call :PRINT_SUCCESS "¹¤×÷Ê÷ÒÑÉ¾³ý"
        call :LOG_ACTION "WORKTREE_REMOVE: !worktree_path!"
    )
)
call :WAIT_KEY
goto MENU