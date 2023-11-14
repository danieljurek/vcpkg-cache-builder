FROM --platform=linux/amd64 mcr.microsoft.com/devcontainers/base:ubuntu

RUN mkdir -p /vcpkg-cache/downloads/

# Set ARCH for vcpkg-bootstrap.sh to succeed
ENV ARCH x86_64
