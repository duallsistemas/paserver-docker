###############################################################
# Copyright (C) 2019 Duall Sistemas Ltda.
###############################################################

###############################################################
# Preparing the environment:
#
# docker build --force-rm -t paserver .
# docker run -p 9090:9090 -p 64211:64211 -v <your-dir>:/home/paserver -dt paserver
###############################################################

FROM ubuntu:bionic AS downloader

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -qy --no-install-recommends \
    ca-certificates \
    build-essential \
    cmake \
    curl \
    libgnutls28-dev

RUN \
    curl -SOJ http://altd.embarcadero.com/releases/studio/20.0/PAServer/Release2/LinuxPAServer20.0.tar.gz && \
    curl -SL https://github.com/risoflora/libsagui/archive/v2.4.7.tar.gz | tar -zx && \
    cd libsagui-2.4.7/ && mkdir build && cd build/ && \
    cmake -DSG_HTTPS_SUPPORT=ON .. && \
    make sagui install/strip

FROM ubuntu:bionic

LABEL Maintainer="Duall Sistemas <duallsistemas@gmail.com>"
LABEL Name="PAServer"
LABEL Version="10.3.3"

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -qy --no-install-recommends \
    ca-certificates \
    build-essential \
    libltdl7 \
    openssl1.0 \
    libc-ares2 \
    libcurl3 \
    libcurl-openssl1.0-dev \
    libxml2 \
    libxslt1.1

COPY --from=downloader /LinuxPAServer20.0.tar.gz /

COPY --from=downloader /usr/local/lib/libsagui.so.2.4.7 /usr/lib/x86_64-linux-gnu/

COPY mime.types /etc/

COPY duallapi.config /etc/

RUN \
    ln -sf '/usr/lib/x86_64-linux-gnu/libcares.so.2' '/usr/lib/x86_64-linux-gnu/libcares.so' && \
    ln -sf '/usr/lib/x86_64-linux-gnu/libcrypto.so.1.0.0' '/usr/lib/x86_64-linux-gnu/libcrypto.so' && \
    ln -sf '/usr/lib/x86_64-linux-gnu/libcurl.so.4' '/usr/lib/x86_64-linux-gnu/libcurl.so' && \
    ln -sf '/usr/lib/x86_64-linux-gnu/libsagui.so.2.4.7' '/usr/lib/x86_64-linux-gnu/libsagui.so.2' && \
    ln -sf '/usr/lib/x86_64-linux-gnu/libsagui.so.2.4.7' '/usr/lib/x86_64-linux-gnu/libsagui.so' && \
    ldconfig && \
    tar -zxf LinuxPAServer20.0.tar.gz && \
    mv PAServer-20.0/paserver.config /etc/ && \
    mv PAServer-20.0/* /usr/bin/ && \
    groupadd paserver && useradd paserver -m -g paserver

WORKDIR /usr/bin

USER paserver

VOLUME [ "/home/paserver" ]

EXPOSE 9090/tcp 64211/tcp

ENTRYPOINT [ "paserver", "-scratchdir=/home/paserver", "-unrestricted", "-config=/etc/paserver.config" ]

CMD [ "-password=" ]
