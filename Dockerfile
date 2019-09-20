FROM alpine:latest
LABEL maintainer="lynx <wyy.hxl@gmail.com>"

ENV ROOT        /tmp/app
ENV SKYNET_PATH /skynet
ENV LOGGER      nil
ENV STANDALONE  nil
ENV MASTER      nil
ENV HARBOR      0
ENV PATH="${SKYNET_PATH}:/skynet/3rd/lua:${PATH}"
ENV LUA_PATH="${SKYNET_PATH}/lualib/?.lua;${SKYNET_PATH}/lualib/?/init.lua;./?.lua;./?/init.lua"
ENV LUA_CPATH="${SKYNET_PATH}/luaclib/?.so;./?.so"

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
    \
    && cd /tmp \
    && wget https://github.com/hanslub42/rlwrap/releases/download/v0.43/rlwrap-0.43.tar.gz \
    && tar -zxvf rlwrap-0.43.tar.gz \
    && cd rlwrap-0.43 \
    && ./configure && make && make install \
    && cd /tmp && rm -rf rlwrap-0.43 \
    \
    && cd /skynet \
    && runDeps="$( \
        scanelf --needed --nobanner --format '%n#p' --recursive 3rd/lua/lua skynet \
            | tr ',' '\n' \
            | sort -u \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
        )" \
    && apk add --virtual .run-deps $runDeps \
    && apk del .build-deps


WORKDIR ${ROOT}
CMD ["skynet", "config"]
