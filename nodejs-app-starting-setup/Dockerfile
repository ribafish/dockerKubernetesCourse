FROM node

# Change work directory to /app
WORKDIR /app

# COPY from to -> copies package.json to /app. This way npm install will only run if package.json is changed
COPY package.json /app

# Run npm install -> from inside /app
RUN npm install

# COPY from to -> copies everything (excluding Dockerfile) from the folder where the Dockerfile is to `/app` folder in the container
COPY . /app

# We want to expose a port to the localhost machine - This is for the documentation purposes, this won't actually do anything.
# To actually expose a port to localhost, when starting a container with docker run, you need to add -p or --publish localHostPort:dockerPort
EXPOSE 80

# CMD command will run when the container is started, instead of RUN, which executes when building the image
CMD ["node", "server.js"]
