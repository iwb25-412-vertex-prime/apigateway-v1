@echo off
echo Setting up MySQL database for User Portal...

REM Check if MySQL is running
mysql --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: MySQL is not installed or not in PATH
    echo Please install MySQL and ensure it's in your system PATH
    pause
    exit /b 1
)

echo Creating database and tables...
mysql -u root -p < ballerina-backend/database/schema.sql

if %errorlevel% equ 0 (
    echo Database setup completed successfully!
    echo.
    echo Next steps:
    echo 1. Update ballerina-backend/Config.toml with your MySQL credentials
    echo 2. Start the backend: cd ballerina-backend && bal run
    echo 3. Start the frontend: cd userportal && npm run dev
) else (
    echo Database setup failed. Please check your MySQL connection and credentials.
)

pause