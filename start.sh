#!/bin/sh

# Start the FastAPI backend server in the background
echo "Starting FastAPI server..."
cd /app/backend
python -m uvicorn main:app --host 0.0.0.0 --port 8000 &

# Start the Next.js frontend server in the foreground
echo "Starting Next.js server..."
cd /app/frontend
# Call 'next start' directly from the node_modules bin
./node_modules/.bin/next start