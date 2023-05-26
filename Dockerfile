# Building an Phoenix (Elixir) Release targeting Amazon Linux for EC2
# By https://github.com/treygriffith
# Original by the Phoenix team: https://hexdocs.pm/phoenix/releases.html#containers
#
# Note: Build context should be the application root
# Build Args:
# OTP_VERSION - the OTP version to target, like 23.0
# ELIXIR_VERSION - the Elixir version to target, like 1.10.4
#
# If you have other environment variables in config/prod.secret.exs, add them as `ARG`s in this file

FROM amazonlinux:2023 AS build

RUN yum -y update

# https://gist.github.com/techgaun/335ef6f6abb5a254c66d73ac6b390262
RUN yum -y groupinstall "Development Tools" && \
    yum -y install openssl-devel ncurses-devel

# Install Erlang
ARG OTP_VERSION
WORKDIR /tmp
RUN mkdir -p otp && \
    curl -LS "https://github.com/erlang/otp/releases/download/OTP-${OTP_VERSION}/otp_src_${OTP_VERSION}.tar.gz" --output otp.tar.gz && \
    tar xfz otp.tar.gz -C otp --strip-components=1
WORKDIR /tmp/otp
RUN ./configure && make && make install

# Install Elixir
ARG ELIXIR_VERSION
ENV LC_ALL en_US.UTF-8
WORKDIR /tmp
RUN mkdir -p elixir && \
    curl -LS "https://github.com/elixir-lang/elixir/archive/v${ELIXIR_VERSION}.tar.gz" --output elixir.tar.gz && \
    tar xfz elixir.tar.gz -C elixir --strip-components=1
WORKDIR /tmp/elixir
RUN make install -e PATH="${PATH}:/usr/local/bin"

# Install hex + rebar
RUN mix local.hex --force && mix local.rebar --force

# Install node (18.12.1)
RUN yum -y install nodejs

# Install Python (3.9.16)
RUN yum -y install python3 python3-pip

# Our working directory within the container
WORKDIR /opt/build

# Add our release script to the container, named `release` and
# placed into the ./bin/ directory in our project root
ADD ./bin/build_release ./bin/build_release

# This is our entry point, make sure to run
# `chmod +x bin/build_release` to make this script executable
# CMD ["bin/build_release", "prod", "master"]
