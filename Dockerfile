#
# Installing composer dependecies
#

FROM composer:1.9 as vendor

WORKDIR /app

COPY . .

RUN composer install --no-ansi --no-dev --no-interaction --no-plugins --no-progress --no-scripts --no-suggest --optimize-autoloader

#
# Build rr-grpc and protoc-gen-php-grpc
# Compile proto files.
#

FROM golang:1.13-alpine as golang

RUN apk --update --no-cache add bash

RUN apk --update --no-cache add \
         --repository=http://dl-cdn.alpinelinux.org/alpine/edge/main \
         --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community \
         grpc

WORKDIR /app

COPY --from=vendor /app .

RUN apk add git protobuf-dev make
RUN make go-install-deps

RUN bash vendor/spiral/php-grpc/build.sh build Linux linux amd64
RUN bash vendor/spiral/php-grpc/build.sh build_protoc Linux linux amd64

RUN protoc -I . -I ./third_party/googleapis --plugin=./vendor/spiral/php-grpc/protoc-gen-php-grpc --php_out=./generated  --openapiv2_out=:.  --php-grpc_out=./generated protos/**/*.proto

#
# Build app image
#

FROM php:7.3-zts-alpine as webserver

RUN apk add --update --no-cache --virtual .build-deps \
        curl \
        autoconf \
        gcc \
        make \
        g++ \
        zlib-dev

WORKDIR /var/www

RUN docker-php-ext-install pdo_mysql bcmath

COPY --from=golang /app/vendor .
COPY --from=golang /app/generated .
COPY --from=golang /app/protos .

RUN apk del .build-deps

# EXPOSE 3000 
# EXPOSE 9001 

CMD ["vendor/spiral/php-grpc/rr-grpc", "serve", "-v", "-d"]


##############################################
#swagger ui
###############################################

FROM swaggerapi/swagger-ui:latest as swagger-ui

WORKDIR /app

COPY ./generated .

WORKDIR /