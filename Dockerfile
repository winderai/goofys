#syntax=docker/dockerfile:1.2

FROM golang:1.16.0 as build-stage

# All these steps will be cached
WORKDIR /go/src

# <- COPY go.mod and go.sum files to the workspace
COPY go.mod .
COPY go.sum .

# Get dependancies - will also be cached if we won't change mod/sum
RUN --mount=type=cache,target=/go/pkg/mod go mod download

# COPY the source code as the last step
COPY api api
COPY internal internal
COPY *.go .

ARG LDFLAGS

RUN --mount=type=cache,target=/root/.cache/go-build --mount=type=cache,target=/go/pkg/mod CGO_ENABLED=0 go build -ldflags "${LDFLAGS}" 

FROM rust:1.53-alpine3.12

WORKDIR /src

RUN apk add git fuse-dev pkgconfig

RUN git clone http://github.com/tnachen/catfs && cd catfs && cargo install --path .

COPY --from=build-stage /go/src/goofys /bin/goofys

ENTRYPOINT ["/bin/goofys"]
