FROM node:20-alpine

WORKDIR /app

RUN apk add --no-cache openssl libc6-compat

COPY backend/package*.json ./
RUN npm install

COPY backend/ ./

RUN npx prisma generate

EXPOSE 3000

CMD ["npx", "nest", "start"]
