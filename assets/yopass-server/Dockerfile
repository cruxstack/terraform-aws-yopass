# --------------------------------------------------------------------- base ---

FROM golang:1.24 AS base

ARG YOPASS_VERSION=latest

ENV GOOS=linux
ENV GOARCH=amd64
ENV CGO_ENABLED=0

RUN mkdir -p /opt/app
WORKDIR /opt/app

RUN git clone https://github.com/jhaals/yopass.git .
RUN if [ "$YOPASS_VERSION" != "latest" ] ; then git checkout $YOPASS_VERSION ; fi
RUN go mod download
RUN cd deploy/cdk && \
    go mod tidy && \
    go build -o bootstrap

# ------------------------------------------------------------------ package ---

FROM alpine:latest AS package

COPY --from=base /opt/app/deploy/cdk/bootstrap /opt/app/dist/bootstrap

RUN apk add zip \
    && cd /opt/app/dist \
    && zip -r /tmp/package.zip .
