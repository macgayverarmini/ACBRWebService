docker build -t acbr-webservice-builder .
docker run --rm -v "$(pwd):/app" acbr-webservice-builder
