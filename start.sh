#!/bin/sh

# Start the FastAPI backend server in the background
echo "Starting FastAPI server..."
cd /app/backend
python -m uvicorn main:app --host 0.0.0.0 --port 8000 &

# Start the Next.js frontend server in the foreground
# It will use the $PORT variable provided by Railway, defaulting to 3000
echo "Starting Next.js server..."
cd /app/frontend
npm start -p ${PORT:=3000}