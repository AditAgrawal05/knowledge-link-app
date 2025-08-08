# Stage 1: Build the Next.js frontend
FROM node:20-slim AS frontend-builder
WORKDIR /app
COPY frontend/package*.json ./
RUN npm install
COPY frontend/ .
RUN npm run build

# --- Final Stage: Production Image ---
FROM python:3.11-slim

# Install Node.js 20.x for running the Next.js server
RUN apt-get update && \
    apt-get install -y curl && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs

WORKDIR /app

# Copy backend code and install Python dependencies
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY backend/ ./backend

# Copy built frontend assets from the builder stage
COPY --from=frontend-builder /app/.next ./frontend/.next
COPY --from=frontend-builder /app/public ./frontend/public
COPY --from=frontend-builder /app/package*.json ./frontend/
COPY --from=frontend-builder /app/next.config.ts ./frontend/

# Install *only* the necessary production dependencies for Next.js
WORKDIR /app/frontend
RUN npm install --production

# Go back to the root, copy the start script, and make it executable
WORKDIR /app
COPY start.sh .
RUN chmod +x ./start.sh

EXPOSE 3000
CMD ["./start.sh"]