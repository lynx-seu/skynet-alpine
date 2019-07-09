FROM alpine:latest
LABEL maintainer="lynx <wyy.hxl@gmail.com>"

ENV ROOT        /tmp/app
ENV SKYNET_PATH /skynet
ENV LOGGER      nil
ENV STANDALONE  nil
ENV HARBOR      0
ENV PATH="${SKYNET_PATH}:/skynet/3rd/lua:${PATH}"

RUN set -ex \
    && apk update && apk upgrade \
    && apk add --no-cache --virtual .build-deps \
        git \
        coreutils \
        linux-headers \
        readline-dev \
        gcc \
        make \
        musl-dev \
    && cd / \
    && git clone https://github.com/cloudwu/skynet.git \
    && make linux -C skynet  \
        MALLOC_STATICLIB="" SKYNET_DEFINES=-DNOUSE_JEMALLOC \
    && cd ${SKYNET_PATH} \
    && rm -rf .git 3rd/lua/*.o 3rd/lua/luac *.md \
    && runDeps="$( \
        scanelf --needed --nobanner --format '%n#p' --recursive 3rd/lua/lua skynet \
            | tr ',' '\n' \
            | sort -u \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
        )" \
    && apk add --virtual .run-deps $runDeps \
    && apk del .build-deps

WORKDIR ${ROOT}
CMD ["/skynet/skynet", "config"]
