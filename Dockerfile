# ---- Builder stage ----
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files first
COPY package*.json ./

# Install ALL dependencies (including dev) to build the frontend
RUN npm ci --no-audit --no-fund

# Copy source and build Vite frontend -> ./dist
COPY . .
RUN npm run build


# ---- Production stage ----
FROM node:18-alpine

WORKDIR /app

# Copy package files again
COPY package*.json ./

# Install ONLY production dependencies, prune aggressively
RUN npm ci --omit=dev --no-audit --no-fund --no-optional && \
    npm cache clean --force && \
    # Remove all unnecessary files from node_modules
    find node_modules -type f \( -name "*.md" -o -name "*.markdown" -o -name "*.txt" -o -name "*.ts" -o -name "*.map" \) -delete && \
    find node_modules -type d \( -name "test" -o -name "tests" -o -name "docs" -o -name "examples" -o -name ".bin" \) -exec rm -rf {} + 2>/dev/null || true && \
    # Also remove any cache directories inside node_modules
    find node_modules -type d -name ".cache" -exec rm -rf {} + 2>/dev/null || true

# Copy built frontend (and strip source maps if any)
COPY --from=builder /app/dist ./dist
RUN find dist -type f -name "*.map" -delete  # remove source maps if present

# Copy server entrypoint
COPY index.js ./

EXPOSE 5000
ENV NODE_ENV=production
CMD ["node", "index.js"]