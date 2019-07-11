FROM mongo

# Create app directory
WORKDIR /usr/src/configs

# Install app dependencies
COPY mongoSetup.js .
COPY setup.sh .
COPY dbSetup.js .

# RUN 명령어는 컨테이너가 생성되기 이전 시점에 즉시 실행되지만 CMD 명령어는 컨테이너가 생성된 이후에 실행된다.
RUN ["chmod", "+x", "./setup.sh"]
CMD ["./setup.sh"]