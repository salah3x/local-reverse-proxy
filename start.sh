#!/bin/sh

rm -rf access.log error.log
touch access.log error.log

if lsof -Pni :443 | grep LISTEN >/dev/null; then
  echo Port 443 is already in use.
  exit 1
fi

if ! cat /etc/os-release | grep Ubuntu >/dev/null; then
  echo Only support Ubuntu.
  exit 1
fi

if ! type -p docker &>/dev/null; then
  echo "Docker is not installed."
  exit 1
fi

if ! docker info > /dev/null 2>&1; then
  echo 'Docker should be up and running.'
  exit 1
fi

if ! type -p openssl &>/dev/null; then
  echo Install openssl...
  apt install openssl
fi

if type -p openssl &>/dev/null; then
  echo Create ssl certificate...
  openssl req -newkey rsa:2048 -new -nodes -x509 -days 365 \
    -out cert.pem \
    -keyout cert-key.pem \
    -subj /C='MA'/ST=' '/L=' '/O=' '/OU=' '/CN=' ' &>/dev/null
fi

echo Starting nginx...
docker run -d \
  -v $(pwd)/nginx.conf:/etc/nginx/nginx.conf \
  -v $(pwd)/configs/location.conf:/etc/nginx/location.conf \
  -v $(pwd)/configs/upstream.conf:/etc/nginx/upstream.conf \
  -v $(pwd)/cert.pem:/root/cert.pem \
  -v $(pwd)/cert-key.pem:/root/cert-key.pem \
  -v $(pwd)/access.log:/root/access.log \
  -v $(pwd)/error.log:/root/error.log \
  -p 80:80 \
  -p 443:443 \
  --name local-reverse-proxy \
  nginx:1-alpine
echo Done
