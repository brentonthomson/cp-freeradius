ARG from=alpine:3.23
FROM ${from} AS build

RUN apk update && apk upgrade && \
    apk add --no-cache build-base curl-dev gdbm-dev hiredis-dev json-c-dev jq krb5-dev libc-dev libcouchbase-dev libidn-dev libmemcached-dev linux-headers mariadb-dev openssl openssl-dev openldap-dev pcre-dev perl-dev postgresql-dev python3-dev ruby-dev samba-dev sqlite-dev talloc-dev unbound-dev unixodbc-dev

ARG VERSION=3.2.8
ARG VERSION_UNDERSCORE=3_2_8

ARG URL=https://github.com/FreeRADIUS/freeradius-server/releases/download/release_${VERSION_UNDERSCORE}/freeradius-server-${VERSION}.tar.gz
ARG NAME=freeradius-server-${VERSION}.tar.gz
ARG DIR=freeradius-server-${VERSION}

RUN wget -q $URL -O $NAME && \
    tar -xf $NAME && \
    cd $DIR && \
    ./configure --prefix=/opt && \
    make -j2 && \
    make install

WORKDIR /

COPY . .

RUN chmod +x post-install.sh && \
    ./post-install.sh

FROM ${from}
COPY --from=build /opt /opt

RUN apk update && \
    apk add --no-cache openssl talloc libressl make pcre libwbclient tzdata && \
    ln -s /opt/etc/raddb /etc/raddb

WORKDIR /opt/

RUN chmod +x entrypoint.sh && \ 
    chmod +x new-certs.sh && \
    ln -s /opt/new-certs.sh /usr/local/bin/new-certs

EXPOSE 1812/udp

HEALTHCHECK --start-period=1m --interval=5m \
    CMD netstat -an | grep 1812 > /dev/null; if [ 0 != $? ]; then exit 1; fi;

ENTRYPOINT ["/opt/entrypoint.sh"]
CMD ["radiusd"] 