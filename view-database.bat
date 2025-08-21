@echo off
echo Viewing User Portal Database...
echo.

REM Check if database exists
if not exist "ballerina-backend\database\userportal.db" (
    echo Database file not found. Make sure the backend has been started at least once.
    pause
    exit /b 1
)

echo Database location: ballerina-backend\database\userportal.db
echo.

REM Try to use sqlite3 if available
sqlite3 -version >nul 2>&1
if %errorlevel% equ 0 (
    echo Opening SQLite command line...
    echo Type .tables to see all tables
    echo Type SELECT * FROM users; to see all users
    echo Type SELECT * FROM jwt_tokens; to see all tokens
    echo Type .quit to exit
    echo.
    sqlite3 "ballerina-backend\database\userportal.db"
) else (
    echo SQLite3 command line not available.
    echo.
    echo Options to view the database:
    echo 1. Download DB Browser for SQLite: https://sqlitebrowser.org/
    echo 2. Use online viewer: https://sqliteviewer.app/
    echo 3. Install SQLite: https://sqlite.org/download.html
    echo.
    echo Database file location: %cd%\ballerina-backend\database\userportal.db
)

pause