# --- Stage 1: Install backend dependencies ---
FROM python:3.11-slim AS python-base
WORKDIR /app/backend
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY ./backend .

# --- Stage 2: Install frontend dependencies and build ---
FROM node:20-slim AS frontend-base
WORKDIR /app/frontend
COPY frontend/package*.json ./
RUN npm install
COPY frontend/ .
RUN npm run build

# --- Final Stage: Combine both apps ---
FROM node:20-slim
WORKDIR /app

# Copy Python and its dependencies from the first stage
COPY --from=python-base /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=python-base /app/backend /app/backend

# Copy the Next.js app from the second stage
COPY --from=frontend-base /app/frontend /app/frontend

# Copy the start script and make it executable
COPY start.sh .
RUN chmod +x start.sh

# Expose the port Next.js runs on
EXPOSE 3000

# The command to run the start script
CMD ["./start.sh"]