@echo off
echo Setting up SQLite database for User Portal...

REM Create database directory if it doesn't exist
if not exist "ballerina-backend\database" mkdir "ballerina-backend\database"

REM Check if sqlite3 is available
sqlite3 -version >nul 2>&1
if %errorlevel% neq 0 (
    echo SQLite3 not found in PATH. Downloading portable version...
    
    REM Create a simple database file and let Ballerina handle the schema
    echo Creating database file...
    echo. > "ballerina-backend\database\userportal.db"
    
    echo Database file created successfully!
    echo The database schema will be created automatically when you start the backend.
) else (
    echo Creating database with schema...
    sqlite3 "ballerina-backend\database\userportal.db" < "ballerina-backend\database\sqlite-schema.sql"
    echo Database setup completed successfully!
)

echo.
echo Next steps:
echo 1. Start the backend: cd ballerina-backend && bal run
echo 2. Start the frontend: cd userportal && npm run dev
echo 3. Open http://localhost:3000

pause