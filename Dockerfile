# Dockerfile

# --- Stage 1: Build the backend base ---
FROM python:3.11-slim AS python-base
WORKDIR /app/backend
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY backend/ .

# --- Stage 2: Build the frontend ---
FROM node:20-slim AS frontend-builder
WORKDIR /app/frontend
COPY frontend/package*.json ./
RUN npm install
COPY frontend/ .
RUN npm run build

# --- Final Stage: Production image ---
FROM node:20-slim
WORKDIR /app

# Install Python runtime
RUN apt-get update && apt-get install -y python3-pip

# Copy Python app and its installed dependencies from the backend base
COPY --from=python-base /app/backend /app/backend
COPY --from=python-base /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages

# Copy the built Next.js app from the frontend builder stage
COPY --from=frontend-builder /app/frontend /app/frontend

# Copy start script and make it executable
COPY start.sh .
RUN chmod +x ./start.sh

EXPOSE 3000
CMD ["./start.sh"]