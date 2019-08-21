FROM node:8.16.1


# Install app dependencies
# A wildcard is used to ensure both package.json AND package-lock.json are copied
# where available (npm@5+)


WORKDIR /etc/fabric
COPY . .


WORKDIR /etc/fabric/ipsum-ledger-app/javascript

RUN ls
RUN cd /etc/fabric/ipsum-ledger-app/javascript && npm install
# If you are building your code for production
# RUN npm ci --only=production


EXPOSE 5000
CMD [ "node", "app.js" ]
