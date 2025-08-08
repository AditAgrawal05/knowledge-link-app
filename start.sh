#!/bin/sh

# Start the FastAPI backend server in the background
echo "Starting FastAPI server..."
cd /app/backend
python3 -m uvicorn main:app --host 127.0.0.1 --port 8000 &

# Start the Next.js frontend server in the foreground
echo "Starting Next.js server..."
cd /app/frontend
./node_modules/.bin/next start