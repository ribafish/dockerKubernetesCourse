FROM node

WORKDIR /app

COPY package.json .

RUN npm install

COPY . .

EXPOSE 80

# Otherwise when we add a bind mount to the sourcecode, node_modules will get overwritten.
VOLUME [ "/app/node_modules" ]

ENV MONGODB_USERNAME=admin
ENV MONGODB_PASSWORD=secret

CMD ["npm", "start"]
