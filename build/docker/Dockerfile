FROM alpine:3.7

EXPOSE 8080
EXPOSE 7946

RUN set -xe; \
    apk update && apk upgrade; \
    # add some usefull tools
    apk add --no-cache bash util-linux coreutils findutils grep \
    openssh curl bind-tools wget; \
    apk add --no-cache linux-headers; \
    apk add --update ca-certificates; 


RUN mkdir  /sample-serf
RUN mkdir  /sample-serf/data/

COPY ./entrypoint.sh /sample-serf/entrypoint.sh
COPY ./node /sample-serf/node

RUN adduser -D -u 1001 application;
RUN chmod +s /bin/ping

RUN chmod +x /sample-serf/entrypoint.sh
RUN chmod +x /sample-serf/node
RUN chown -R 1001 /sample-serf


USER 1001

CMD ["/sample-serf/entrypoint.sh"]
