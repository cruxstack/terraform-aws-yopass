# --------------------------------------------------------------------- base ---

FROM golang:1.19 as base

ARG YOPASS_VERSION=latest

ENV GOOS=linux
ENV GOARCH=amd64
ENV CGO_ENABLED=0

RUN mkdir -p /opt/app
WORKDIR /opt/app

RUN git clone https://github.com/jhaals/yopass.git .
RUN if [ "$YOPASS_VERSION" != "latest" ] ; then git checkout $YOPASS_VERSION ; fi
RUN go mod download
RUN cd deploy/aws-lambda && \
    go mod tidy && \
    go build -o main

# ------------------------------------------------------------------ package ---

FROM alpine:latest as package

COPY --from=base /opt/app/deploy/aws-lambda/main /opt/app/dist/main

RUN apk add zip \
    && cd /opt/app/dist \
    && zip -r /tmp/package.zip .
