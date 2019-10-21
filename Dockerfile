FROM alpine:latest
LABEL maintainer="lynx <wyy.hxl@gmail.com>"

ENV PATH="/skynet:${PATH}"

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
    \
    && cd / \
    && git clone https://github.com/cloudwu/skynet.git \
    && make linux -C skynet  \
        MALLOC_STATICLIB="" SKYNET_DEFINES=-DNOUSE_JEMALLOC \
    && cd /skynet && rm -rf .git 3rd \
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
        scanelf --needed --nobanner --format '%n#p' \
            --recursive  /usr/local/bin/rlwrap /usr/local/bin/lua /skynet/skynet \
            | tr ',' '\n' \
            | sort -u \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
        )" \
    && apk add --virtual .run-deps $runDeps \
    && apk del .build-deps

WORKDIR /tmp/app

# ONBUILD ENV LUA_VERSION=5.3.5
# ONBUILD ENV LUAROCKS_VERSION=3.2.1
# ONBUILD RUN apk add --no-cache --virtual .build-deps \
#         git \
#         coreutils \
#         linux-headers \
#         readline-dev \
#         gcc \
#         curl \
#         unzip \
#         make \
#         musl-dev \
#     \
#     && wget -c https://www.lua.org/ftp/lua-${LUA_VERSION}.tar.gz \
#         -O - | tar -xzf - \
#     && cd lua-${LUA_VERSION} \
#     && make -j"$(nproc)" linux \
#     && make install \
#     && cd .. \
#     && rm -rf lua-${LUA_VERSION} \
#     \
#     && wget https://luarocks.github.io/luarocks/releases/luarocks-${LUAROCKS_VERSION}.tar.gz \
#         -O - | tar -xzf - \
#     && cd luarocks-${LUAROCKS_VERSION} \
#     && ./configure --with-lua=/usr/local \
#     && make build \
#     && make install \
#     && cd .. \
#     && rm -rf luarocks-${LUAROCKS_VERSION} \
#     \
#     && apk del .build-deps

ONBUILD CMD ["skynet", "config"]

