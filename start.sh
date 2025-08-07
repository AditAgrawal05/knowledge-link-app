#!/bin/sh

# We are temporarily disabling the backend to test the frontend
# echo "Starting FastAPI server..."
# cd /app/backend
# python -m uvicorn main:app --host 0.0.0.0 --port 8000 &

# Start the Next.js frontend server in the foreground
echo "Starting Next.js server..."
cd /app/frontend
npm start