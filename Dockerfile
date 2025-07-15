ARG TAG
ARG GO_VERSION

FROM golang:${GO_VERSION} AS builder

WORKDIR /app

COPY ./portainer /portainer
COPY ./compose-unpacker/ /app

RUN go mod download && make

FROM portainer/compose-unpacker:${TAG}

COPY --from=builder /app/dist/compose-unpacker /app/compose-unpacker
