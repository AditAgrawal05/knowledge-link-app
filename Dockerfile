# --- Stage 1: Build the Next.js frontend ---
FROM node:20-slim AS frontend-builder
WORKDIR /app

# Copy package files to the frontend subdirectory
COPY frontend/package*.json ./frontend/

# Set the working directory to the frontend folder and install dependencies
WORKDIR /app/frontend
RUN npm install

# Copy the rest of the frontend source code
COPY frontend/ .

# Run the build, which creates the 'out' folder inside /app/frontend
RUN npm run build


# --- Stage 2: Create the final production image ---
FROM python:3.11-slim

# Install Node.js and npm for the Next.js production server
RUN apt-get update && \
    apt-get install -y curl && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs

WORKDIR /app

# Copy Python backend and install dependencies
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY ./backend ./backend

# Copy the Next.js app with its production dependencies
COPY --from=frontend-builder /app/frontend /app/frontend

# Copy the start script and make it executable
COPY start.sh .
RUN chmod +x start.sh

# Expose the port Next.js runs on
EXPOSE 3000

# Command to run our start script
CMD ["./start.sh"]