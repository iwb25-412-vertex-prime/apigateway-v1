#!/bin/bash

echo "Starting Ballerina Backend and Next.js Frontend..."

echo ""
echo "Starting Ballerina backend on port 8080..."
cd ballerina-backend
bal run &
BACKEND_PID=$!
cd ..

echo ""
echo "Waiting 5 seconds for backend to start..."
sleep 5

echo ""
echo "Starting Next.js frontend on port 3000..."
cd userportal
npm run dev &
FRONTEND_PID=$!
cd ..

echo ""
echo "Both services are running..."
echo "Backend: http://localhost:8080"
echo "Frontend: http://localhost:3000"
echo ""
echo "Press Ctrl+C to stop both services"

# Function to cleanup processes
cleanup() {
    echo ""
    echo "Stopping services..."
    kill $BACKEND_PID 2>/dev/null
    kill $FRONTEND_PID 2>/dev/null
    exit 0
}

# Set trap to cleanup on script exit
trap cleanup SIGINT SIGTERM

# Wait for processes
wait