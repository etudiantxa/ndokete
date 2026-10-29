FROM node:20-alpine

WORKDIR /app

Run apk add --no-cache openssl libc6-compat

COPY package*.json ./
RUN npm install

COPY . .

RUN npx prisma generate
RUN npm run build

EXPOSE 3000

CMD ["sh", "-c", "npx prisma db push --accept-data-loss && npx prisma db seed && node dist/src/main.js"]
