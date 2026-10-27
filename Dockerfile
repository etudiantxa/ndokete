FROM node:20-alpine

WORKDIR /app

RUN apk add --no-cache openssl libc6-compat

COPY backend/package*.json ./
RUN npm install

COPY backend/ ./

RUN npx prisma generate
RUN npm run build

EXPOSE 3000

CMD ["sh", "-c", "node dist/src/main.js || node dist/main.js"]
