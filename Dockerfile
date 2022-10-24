FROM golang:1.19-alpine AS xray
RUN apk update && apk add --no-cache git
WORKDIR /go/src/xray/core
RUN git clone --progress https://github.com/XTLS/Xray-core.git . && \
    go mod download && \
    CGO_ENABLED=0 go build -o /tmp/xray -trimpath -ldflags "-s -w -buildid=" ./main

FROM caddy:2.6.2-builder-alpine AS caddy
RUN xcaddy build latest

WORKDIR /root
COPY --from=xray /tmp/xray /usr/bin 
COPY entrypoint.sh /root/entrypoint.sh

RUN set -ex \
	&& mkdir -p /etc/caddy/ /etc/xray \
	&& apk add --no-cache ca-certificates tor wget \
	&& chmod +x /usr/bin/xray \
	&& chmod +x /usr/bin/caddy \
	&& chmod +x /root/entrypoint.sh 

COPY conf/Caddyfile /conf/Caddyfile
COPY conf/config.json /conf/config.json		

CMD /root/entrypoint.sh
