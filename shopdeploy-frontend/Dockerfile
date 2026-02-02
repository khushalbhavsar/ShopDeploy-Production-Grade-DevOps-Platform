# Multi-stage build for optimized production image
FROM node:18-alpine AS builder

# Build arguments for environment variables
ARG VITE_API_URL=http://localhost:5000/api
ENV VITE_API_URL=$VITE_API_URL

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy application code
COPY . .

# Build the application with environment variables
RUN npm run build

# Production stage - using nginx-unprivileged for non-root execution
# This image is specifically designed to run as non-root user (UID 101)
FROM nginxinc/nginx-unprivileged:alpine

# Copy custom nginx configuration (must listen on 8080 for unprivileged)
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built assets from builder stage
COPY --from=builder /app/dist /usr/share/nginx/html

# nginx-unprivileged runs on port 8080 by default
EXPOSE 8080

# Health check using port 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/ || exit 1

# Start nginx (runs as non-root user 101)
CMD ["nginx", "-g", "daemon off;"]
