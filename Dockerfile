FROM alpine:latest

RUN apk update
RUN apk add --no-cache curl jq bash ca-certificates

ENV CF_CLI_VERSION "7.7.14"

RUN curl -L "https://packages.cloudfoundry.org/stable?release=linux64-binary&version=${CF_CLI_VERSION}&source=github-rel" | tar -zx -C /usr/local/bin

ADD entrypoint.sh /entrypoint.sh

COPY blue-green.sh /usr/local/bin/blue-green
RUN chmod +x /usr/local/bin/blue-green

ENTRYPOINT ["/entrypoint.sh"]
