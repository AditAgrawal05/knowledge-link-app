# Stage 1: Build the Next.js frontend
FROM node:20-slim AS frontend-builder
WORKDIR /app/frontend
COPY frontend/package*.json ./
RUN npm install
COPY frontend/ .
RUN npm run build

# Stage 2: Prepare the Python environment
FROM python:3.11-slim AS python-base
WORKDIR /app
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY backend/ ./backend

# --- Final Stage: Production image ---
FROM python:3.11-slim

# Install Node.js for running the Next.js production server
RUN apt-get update && \
    apt-get install -y curl && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs

WORKDIR /app

# Copy backend and its installed dependencies from the python-base stage
COPY --from=python-base /app/backend /app/backend
COPY --from=python-base /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages

# Copy the built frontend app from the frontend-builder stage
COPY --from=frontend-builder /app/frontend /app/frontend

# Copy the start script and make it executable
COPY start.sh .
RUN chmod +x ./start.sh

EXPOSE 3000
CMD ["./start.sh"]