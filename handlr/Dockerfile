FROM node:4.2.2
WORKDIR /home
RUN mkdir gamerist
RUN mkdir gamerist/handlr
ADD package.json gamerist/handlr
ADD npminstall.sh gamerist/handlr
WORKDIR /home/gamerist/handlr
RUN ./npminstall.sh
ADD . /home/gamerist/handlr

