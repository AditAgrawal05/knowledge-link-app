# --- Stage 1: Build the Next.js frontend ---
FROM node:20-slim AS frontend-builder
WORKDIR /app/frontend
COPY frontend/package*.json ./
RUN npm install
COPY frontend/ .
RUN npm run build

# --- Stage 2: Build the Python backend and serve the app ---
FROM python:3.11-slim
WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY ./backend .
COPY --from=frontend-builder /app/frontend/out ./static
EXPOSE 8000
CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]