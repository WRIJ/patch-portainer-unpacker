ARG PORTAINER_TAG
ARG GO_VERSION

FROM golang:${GO_VERSION} AS builder

WORKDIR /app

COPY ./packages/portainer /portainer
COPY ./packages/compose-unpacker/ /app

RUN go mod download && make

FROM portainer/compose-unpacker:${PORTAINER_TAG}

COPY --from=builder /app/dist/compose-unpacker /app/compose-unpacker
