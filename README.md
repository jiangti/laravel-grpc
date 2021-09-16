# ProtoBuf Generation

docker-compose run go protoc -I . -I ./third_party/googleapis --plugin=./vendor/spiral/php-grpc/protoc-gen-php-grpc --php_out=./generated  --openapiv2_out=./generated --php-grpc_out=./generated protos/**/*.proto

