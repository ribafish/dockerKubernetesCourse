FROM node

WORKDIR /app

COPY package.json .

RUN npm install

COPY . .

EXPOSE 3000

# Otherwise when we add a bind mount to the sourcecode, node_modules will get overwritten.
VOLUME [ "/app/node_modules" ]

CMD ["npm", "start"]
