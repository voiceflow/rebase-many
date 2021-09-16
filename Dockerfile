FROM alpine:3.14.2

LABEL version="1.0.0"
LABEL repository="http://github.com/voiceflow/rebase-many"
LABEL homepage="http://github.com/voiceflow/rebase-many"
LABEL maintainer="Voiceflow"
LABEL "com.github.actions.name"="Rebase Many"
LABEL "com.github.actions.description"="Rebases multiple pull requests within a repository"
LABEL "com.github.actions.icon"="git-pull-request"
LABEL "com.github.actions.color"="purple"

RUN apk --no-cache add jq bash curl git git-lfs wget

# Install Github CLI
RUN mkdir /ghcli
WORKDIR /ghcli
RUN wget https://github.com/cli/cli/releases/download/v2.0.0/gh_2.0.0_linux_386.tar.gz -O ghcli.tar.gz
RUN tar --strip-components=1 -xf ghcli.tar.gz

# Get Rebase Action
RUN mkdir /rebase
WORKDIR /rebase
RUN wget https://github.com/cirrus-actions/rebase/archive/refs/tags/1.5.tar.gz -O rebase.tar.gz
RUN tar --strip-components=1 -xf rebase.tar.gz

ADD entrypoint.sh /entrypoint.sh

RUN ["chmod", "+x", "/entrypoint.sh"]
RUN ["chmod", "+x", "/rebase/entrypoint.sh"]

ENTRYPOINT ["/entrypoint.sh"]
