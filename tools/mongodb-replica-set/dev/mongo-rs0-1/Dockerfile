FROM mongo

# Working config directory
WORKDIR /usr/src/configs

COPY ./mongo.conf .

EXPOSE 27017

# CMD Instruction
CMD ["--config", "./mongo.conf"]