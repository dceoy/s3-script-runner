FROM public.ecr.aws/amazonlinux/amazonlinux:2023

ADD https://s3.amazonaws.com/mountpoint-s3-release/latest/x86_64/mount-s3.rpm /tmp/mount-s3.rpm
ADD https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip /tmp/awscli.zip

RUN set -e \
      && dnf -y upgrade \
      && dnf install -y --allowerasing \
        ca-certificates curl jq time tree unzip wget /tmp/mount-s3.rpm \
      && dnf -y autoremove \
      && dnf clean all \
      && rm -rf /var/cache/dnf /tmp/mount-s3.rpm

RUN set -e \
      && unzip -d /tmp /tmp/awscli.zip \
      && /tmp/aws/install

ADD executor-on-s3 /usr/local/bin/executor-on-s3

RUN set -e \
      && chmod +x /usr/local/bin/executor-on-s3

ENTRYPOINT ["/usr/local/bin/executor-on-s3"]
