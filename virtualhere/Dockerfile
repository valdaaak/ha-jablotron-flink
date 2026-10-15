ARG BUILD_FROM
FROM ${BUILD_FROM}

ARG BUILD_ARCH

RUN apt-get update \
  && apt-get install -y --no-install-recommends curl ca-certificates usbutils gcc libc6-dev linux-libc-dev \
  && apt-get clean

RUN set -e; \
  case "${BUILD_ARCH}" in \
    amd64)  BIN=vhusbdx86_64 ;; \
    i386)   BIN=vhusbdi386 ;; \
    aarch64) BIN=vhusbdarm64 ;; \
    armv7)  BIN=vhusbdarm ;; \
    armhf)  BIN=vhusbdarm ;; \
    *)      BIN=vhusbdx86_64 ;; \
  esac; \
  echo "Downloading VirtualHere binary: ${BIN}"; \
  curl -fSL "https://www.virtualhere.com/sites/default/files/usbserver/${BIN}" -o /usr/sbin/vhusbd; \
  chmod +x /usr/sbin/vhusbd

COPY usbreset.c /usbreset.c
RUN gcc -O2 -o /usr/local/bin/usbreset /usbreset.c

COPY run.sh /run.sh
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]