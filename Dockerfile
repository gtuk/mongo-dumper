ARG MONGODB_VERSION=latest
FROM mongo:${MONGODB_VERSION}

RUN apt-get update && \
    apt-get install -y gnupg wget

RUN wget https://dl.min.io/client/mc/release/linux-amd64/mc
RUN chmod +x mc

ADD mongo-dumper.sh ./mongo-dumper.sh
RUN chmod +x ./mongo-dumper.sh

ENTRYPOINT ["./mongo-dumper.sh"]
