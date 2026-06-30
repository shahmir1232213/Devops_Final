FROM node:18-alpine

WORKDIR /app

COPY package*.json ./

RUN npm ci --omit=dev --no-audit --no-fund

COPY . .

# Create logs folder and give ownership to node user
RUN mkdir -p /app/logs && \
    chown -R node:node /app

# Drop root privileges
USER node

EXPOSE 5000

ENV NODE_ENV=production

CMD ["node", "index.js"]