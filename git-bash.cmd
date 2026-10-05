@echo off
REM Launch a bash script using Git Bash (not WSL bash) so Windows env vars are inherited.
REM Usage: git-bash.cmd <script.sh> [args...]
REM
REM Herdr sets HERDR_PLUGIN_ROOT, HERDR_PLUGIN_CONTEXT_JSON, HERDR_PLUGIN_CONFIG_DIR,
REM HERDR_WORKSPACE_ID, and HERDR_BIN_PATH as Windows process environment variables.
REM WSL bash (C:\Windows\System32\bash.exe) does NOT inherit Windows env vars unless
REM they are listed in WSLENV. Git Bash (C:\Program Files\Git\usr\bin\bash.exe)
REM inherits them natively. This wrapper finds Git Bash and execs the script with it.
REM
REM --login makes bash source /etc/profile, which adds /usr/bin (dirname, mkdir, tr,
REM jq, fzf, herdr, etc.) to PATH. Without --login, bash starts with only the
REM inherited Windows PATH and coreutils are not found.
REM
REM Search order: RUNTIME_GIT_BASH env var, then common install locations, then PATH.

setlocal

set "GIT_BASH=%RUNTIME_GIT_BASH%"
if defined GIT_BASH (
    if not exist "%GIT_BASH%" set "GIT_BASH="
)

if not defined GIT_BASH (
    for %%G in (
        "C:\Program Files\Git\usr\bin\bash.exe"
        "C:\Program Files (x86)\Git\usr\bin\bash.exe"
        "%LOCALAPPDATA%\Programs\Git\usr\bin\bash.exe"
    ) do (
        if exist %%G (
            set "GIT_BASH=%%~G"
        )
    )
)

if defined GIT_BASH (
    endlocal & set "GIT_BASH=%GIT_BASH%"
    "%GIT_BASH%" --login %*
    exit /b %ERRORLEVEL%
)

endlocal
REM Fall back to bash on PATH (may be WSL bash, which won't inherit env vars,
REM but at least the script runs).
bash --login %*
exit /b %ERRORLEVEL%
