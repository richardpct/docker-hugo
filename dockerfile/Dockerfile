FROM alpine:latest

LABEL maintainer="richardpct"

ENV VERSION 0.59.1

RUN mkdir /tmp/hugo && \
    wget https://github.com/gohugoio/hugo/releases/download/v${VERSION}/hugo_${VERSION}_Linux-64bit.tar.gz \
    -O /tmp/hugo/hugo_${VERSION}_Linux-64bit.tar.gz

RUN tar xzf /tmp/hugo/hugo_${VERSION}_Linux-64bit.tar.gz -C /tmp/hugo && \
    cp /tmp/hugo/hugo /usr/local/bin && \
    rm -rf /tmp/hugo

WORKDIR /var/hugo/richardpct.github.io

VOLUME /var/hugo
VOLUME /var/output

EXPOSE 1313

CMD ["/usr/local/bin/hugo", "server", "--bind", "0.0.0.0", "-D"]
