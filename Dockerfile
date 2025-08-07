# Start with a base image that has Python
FROM python:3.11-slim

# Set the working directory inside the container
ENV APP_HOME=/app
WORKDIR $APP_HOME

# Install Node.js (which includes npm)
RUN apt-get update && apt-get install -y nodejs npm

# Copy all your project files into the container
COPY . .

# --- Install Backend Dependencies ---
WORKDIR $APP_HOME/backend
RUN pip install --no-cache-dir -r requirements.txt

# --- Install Frontend Dependencies & Build ---
WORKDIR $APP_HOME/frontend
RUN npm install
RUN npm run build

# --- Final Setup ---
# Set the main working directory
WORKDIR $APP_HOME

# Make the start script executable
RUN chmod +x ./start.sh

# Expose the port Next.js runs on
EXPOSE 3000

# The command to run our start script
CMD ["./start.sh"]