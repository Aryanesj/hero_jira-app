FROM node:14 AS Production

ENV NOVE_ENV=production

WORKDIR /app

COPY package*.json .

RUN npm install && \
    npm install pm2 -g

COPY . .

RUN npm run build

CMD npm run start:production
