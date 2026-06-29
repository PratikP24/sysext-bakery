FROM alpine:3.21

RUN apk update && apk add --no-cache \
    bash \
    curl \
    wget \
    git \
    openssh \
    sudo \
    shadow \
    docker-cli \
    squashfs-tools

# Create a non-root dev user
RUN adduser -D -s /bin/bash devuser && \
    echo "devuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER devuser
WORKDIR /workspace

CMD ["sleep", "infinity"]
