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

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get -qy install --no-install-recommends apt-utils 2>&1 && \
    apt-get -qy install ca-certificates build-essential cmake curl libgnutls28-dev

RUN \
    curl -SOJ http://altd.embarcadero.com/releases/studio/20.0/PAServer/Release3/LinuxPAServer20.0.tar.gz && \
    curl -SL https://github.com/risoflora/libsagui/archive/v2.5.2.tar.gz | tar -zx && \
    cd libsagui-2.5.2/ && mkdir build && cd build/ && \
    cmake -DSG_HTTPS_SUPPORT=ON .. && \
    make sagui install/strip

FROM ubuntu:bionic

LABEL Maintainer="Duall Sistemas <duallsistemas@gmail.com>"
LABEL Name="PAServer"
LABEL Version="10.3.3"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get -qy install --no-install-recommends apt-utils 2>&1 && \
    apt-get -qy install \
        ca-certificates \
        build-essential \
        libltdl7 \
        libgnutls30 \
        openssl1.0 \
        libc-ares2 \
        libcurl3 \
        libcurl-openssl1.0-dev \
        libxml2 \
        libxslt1.1 \
        libfbclient2 && \
    apt-get autoremove && apt-get autoclean && rm -rf /var/lib/apt/lists/*

COPY --from=downloader /LinuxPAServer20.0.tar.gz /

COPY --from=downloader /usr/local/lib/libsagui.so.2.5.2 /usr/lib/x86_64-linux-gnu/

COPY mime.types /etc/

COPY duallservice.config /etc/

RUN \
    ln -sf '/lib/x86_64-linux-gnu/libz.so.1' '/usr/lib/x86_64-linux-gnu/libz.so' && \
    ln -sf '/usr/lib/x86_64-linux-gnu/libcares.so.2' '/usr/lib/x86_64-linux-gnu/libcares.so' && \
    ln -sf '/usr/lib/x86_64-linux-gnu/libcrypto.so.1.0.0' '/usr/lib/x86_64-linux-gnu/libcrypto.so' && \
    ln -sf '/usr/lib/x86_64-linux-gnu/libcurl.so.4' '/usr/lib/x86_64-linux-gnu/libcurl.so' && \
    ln -sf '/usr/lib/x86_64-linux-gnu/libxml2.so.2' '/usr/lib/x86_64-linux-gnu/libxml2.so' && \
    ln -sf '/usr/lib/x86_64-linux-gnu/libsagui.so.2.5.2' '/usr/lib/x86_64-linux-gnu/libsagui.so.2' && \
    ln -sf '/usr/lib/x86_64-linux-gnu/libsagui.so.2.5.2' '/usr/lib/x86_64-linux-gnu/libsagui.so' && \
    ldconfig

RUN \
    tar -zxf LinuxPAServer20.0.tar.gz && \
    mv PAServer-20.0/paserver.config /etc/ && \
    mv PAServer-20.0/* /usr/bin/

RUN groupadd paserver && useradd paserver -m -g paserver

WORKDIR /usr/bin

USER paserver

VOLUME [ "/home/paserver" ]

EXPOSE 9090/tcp 64211/tcp

CMD [ "paserver", "-scratchdir=/home/paserver", "-unrestricted", "-password=", "-config=/etc/paserver.config" ]

ENV DEBIAN_FRONTEND=
