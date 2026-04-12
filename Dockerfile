# ---------- Builder Stage ----------
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./


RUN npm install --omit=dev

COPY src/ ./src/


# ---------- Final Stage ----------
FROM node:20-alpine

# Create non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy only required files from builder
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/src ./src

ENV NODE_ENV=production

RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
CMD wget -qO- http://localhost:8080/ || exit 1

CMD ["node", "src/index.js"]
