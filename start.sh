#!/bin/sh

# Start the FastAPI backend server in the background, listening internally
echo "Starting FastAPI server..."
cd /app/backend
python3 -m uvicorn main:app --host 127.0.0.1 --port 8000 &

# Start the Next.js frontend server in the foreground on the public port
echo "Starting Next.js server..."
cd /app/frontend
# 'next start' will automatically use the PORT env var provided by Railway
node_modules/.bin/next start