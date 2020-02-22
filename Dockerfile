FROM alpine:3.10.3

LABEL "com.github.actions.name"="Add Label when a pull request require attention."
LABEL "com.github.actions.description"="A GitHub action to add an attention label on an open pull-request after certain days."
LABEL "com.github.actions.icon"="tag"
LABEL "com.github.actions.color"="blue"

LABEL maintainer="Manish Rathi <manishrathi19902013@gmail.com>"

RUN apk add --no-cache bash curl jq coreutils

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
