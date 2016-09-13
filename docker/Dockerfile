# Dockerfile.alpine
FROM index.tenxcloud.com/docker_library/alpine:edge

# Install node.js by apk
RUN echo '@edge http://nl.alpinelinux.org/alpine/edge/main' >> /etc/apk/repositories
RUN apk update && apk upgrade
RUN apk add --no-cache nodejs-lts@edge

# If you have native dependencies, you'll need extra tools
# RUN apk add --no-cache make gcc g++ python

# Create app directory
RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

# If your project depends on many package, you can use cnpm instead of npm
# RUN npm install cnpm -g --registry=https://registry.npm.taobao.org
# RUN cnpm install

# Install app dependencies
COPY package.json /usr/src/app/
# RUN npm install
RUN npm install --registry=https://registry.npm.taobao.org --production
RUN npm install nodemon --registry=https://registry.npm.taobao.org --production

# Bundle app source
COPY . /usr/src/app

RUN npm run compile

# Expose port
# ENV PORT 3000
ENV NODE_ENV production
EXPOSE 3000

# ENTRYPOINT node app/home/index.js
ENTRYPOINT nodemon src/index.coffee
