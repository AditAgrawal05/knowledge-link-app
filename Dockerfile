# --- Stage 1: Build the Next.js frontend ---
FROM node:20-slim AS frontend-builder
WORKDIR /app
COPY frontend/package*.json ./
RUN npm install
COPY frontend/ .
RUN npm run build

# --- Stage 2: Create the final production image ---
FROM python:3.11-slim

# Install Node.js and npm
RUN apt-get update && \
    apt-get install -y curl && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs

WORKDIR /app

# Copy Python backend and install dependencies
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY ./backend ./backend

# Copy the Next.js production dependencies (node_modules)
COPY --from=frontend-builder /app/node_modules /app/frontend/node_modules
# Copy the rest of the Next.js app
COPY --from=frontend-builder /app /app/frontend

# --- THIS IS THE KEY CHANGE ---
# Copy the *built static files* from the 'out' folder to a new '/app/static' folder
COPY --from=frontend-builder /app/out /app/static

# Copy and prepare the start script
COPY start.sh .
RUN chmod +x start.sh

# Expose the port Next.js runs on
EXPOSE 3000

# Command to run our start script
CMD ["./start.sh"]