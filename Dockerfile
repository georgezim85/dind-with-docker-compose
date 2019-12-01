FROM docker:19.03.1
RUN apk update && apk add --no-cache curl py-pip python-dev libffi-dev openssl-dev gcc libc-dev make git openssh openssh-client
RUN apk update && apk add --no-cache python3 python3-dev
RUN pip3 install docker-compose
RUN docker-compose -v
