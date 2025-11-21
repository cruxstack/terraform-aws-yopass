# --------------------------------------------------------------------- base ---

FROM node:20 AS base

RUN mkdir -p /opt/app
WORKDIR /opt/app

ARG YOPASS_VERSION=latest

RUN git clone https://github.com/jhaals/yopass.git .
RUN if [ "$YOPASS_VERSION" != "latest" ] ; then git checkout $YOPASS_VERSION ; fi

ARG YOPASS_BACKEND_URL="https://my-domain.com"
RUN cd website && \
    yarn install && \
    YOPASS_BACKEND_URL="$YOPASS_BACKEND_URL" yarn build

# ------------------------------------------------------------------ package ---

FROM alpine:latest AS package

COPY --from=base /opt/app/website/dist/ /opt/app/dist/

RUN apk add zip \
    && cd /opt/app/dist \
    && zip -r /tmp/package.zip .
