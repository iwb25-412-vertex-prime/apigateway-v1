#!/bin/bash

echo "Setting up MySQL database for User Portal..."

# Check if MySQL is installed
if ! command -v mysql &> /dev/null; then
    echo "Error: MySQL is not installed or not in PATH"
    echo "Please install MySQL first:"
    echo "  - Ubuntu/Debian: sudo apt-get install mysql-server"
    echo "  - macOS: brew install mysql"
    echo "  - CentOS/RHEL: sudo yum install mysql-server"
    exit 1
fi

echo "Creating database and tables..."
mysql -u root -p < ballerina-backend/database/schema.sql

if [ $? -eq 0 ]; then
    echo "Database setup completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Update ballerina-backend/Config.toml with your MySQL credentials"
    echo "2. Start the backend: cd ballerina-backend && bal run"
    echo "3. Start the frontend: cd userportal && npm run dev"
else
    echo "Database setup failed. Please check your MySQL connection and credentials."
    exit 1
fi