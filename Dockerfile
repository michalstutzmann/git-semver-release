FROM alpine:3.23.4

ARG VERSION=dev

RUN apk add --no-cache bash git \
    && git config --system --add safe.directory '*'

COPY git-semver-release /usr/local/bin/git-semver-release
RUN sed -i "s/^readonly VERSION='dev'\$/readonly VERSION='${VERSION}'/" /usr/local/bin/git-semver-release \
    && chmod +x /usr/local/bin/git-semver-release

WORKDIR /home

ENTRYPOINT ["git-semver-release"]
CMD ["version"]
