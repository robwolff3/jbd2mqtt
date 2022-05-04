FROM node:18-bullseye-slim
RUN apt update
RUN apt-get install -y git python3 make g++

RUN git clone https://github.com/mickwheelz/NodeJBD.git

WORKDIR "/NodeJBD"

RUN npm install

RUN npm link

CMD node-jbd