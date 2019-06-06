FROM fedora:22 AS builder

WORKDIR /tmp/bin/

#install required libraries & clean up to keep thin layer
RUN dnf groupinstall -y "Development Tools" "Development Libraries" \
    && dnf install -y bzip2 tar libtool flex bison glibc-static \
    && dnf autoremove -y && dnf clean all -y

#download & make mount.cifs from source
RUN (cd /tmp; curl -Lo cifs-utils.tar.bz2 http://ftp.samba.org/pub/linux-cifs/cifs-utils/cifs-utils-6.5.tar.bz2) \
    && (cd /tmp; mkdir cifs-utils; tar -xf cifs-utils.tar.bz2 -C cifs-utils --strip-components=1; rm cifs-utils.tar.bz2) \ 
    && (cd /tmp/cifs-utils/; ./configure && make -j) \
    && mkdir -p /tmp/bin/ \
    && cp /tmp/cifs-utils/mount.cifs /tmp/bin/

#download & make jq from source
RUN (cd /tmp; curl -Lo jq.tar.gz https://github.com/stedolan/jq/releases/download/jq-1.5/jq-1.5.tar.gz) \
    && (cd /tmp; mkdir jq; tar -xf jq.tar.gz -C jq --strip-components=1; rm jq.tar.gz) \
    && (cd /tmp/jq/; autoreconf -i && ./configure --enable-all-static && make -j) \
    && mkdir -p /tmp/bin/ \
    && ls /tmp/jq \
    && cp /tmp/jq/jq /tmp/bin/

FROM flynn/busybox

WORKDIR /tmp/bin/

COPY --from=builder /tmp/bin/mount.cifs /tmp/bin/mount.cifs
COPY --from=builder /tmp/bin/jq /tmp/bin/jq

COPY run.sh /tmp/bin/run.sh
COPY cifs.sh /tmp/bin/cifs.sh

ENTRYPOINT ["/tmp/bin/run.sh"]
