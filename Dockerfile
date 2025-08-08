# Stage 1: Prepare the Python environment with all dependencies installed
FROM python:3.11-slim AS python-base
WORKDIR /app
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY backend/ ./backend

# Stage 2: Build the Next.js frontend
FROM node:20-slim AS frontend-builder
WORKDIR /app
COPY frontend/ .
RUN npm install
RUN npm run build

# --- Final Stage: Production image ---
FROM node:20-slim
WORKDIR /app

# Install the missing OpenSSL system library (libssl3)
RUN apt-get update && apt-get install -y libssl3

# Copy the entire working Python installation
COPY --from=python-base /usr/local /usr/local

# Copy the built Next.js app
COPY --from=frontend-builder /app /app/frontend

# Copy the Python source code
COPY --from=python-base /app/backend /app/backend

# Copy start script and make it executable
COPY start.sh .
RUN chmod +x ./start.sh

EXPOSE 3000
CMD ["./start.sh"]