
# ---
# Build arguments
# ---
ARG DOCKER_PARENT_IMAGE=hsteinshiromoto/alpix:latest
FROM $DOCKER_PARENT_IMAGE

# NB: Arguments should come after FROM otherwise they're deleted
ARG BUILD_DATE
ARG USER=user

# ---
# Enviroment variables
# ---
ENV LANG=C.UTF-8 \
	LC_ALL=C.UTF-8
ENV TZ=Australia/Sydney

ENV HOME=/home/$USER
ENV WORKDIR=$HOME

# Set container time zone
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

LABEL org.label-schema.build-date=$BUILD_DATE \
	maintainer="hsteinshiromoto@gmail.com"

RUN apk add bash

ENV SHELL=/bin/bash

SHELL ["/bin/bash", "-c"]

RUN apk --no-cache add \
	autoconf \
	automake \
	bat \
	build-base \
	cargo \
	cmake \
	curl \
	coreutils \
	curl \
	fd \
	fzf \
	gcc \
	gettext-tiny-dev \
	git \
	git-flow \
	libgcc \
	lazygit \
	libtool \
	musl \
	neovim \
	ninja \
	npm \
	pkgconf \
	ripgrep \
	shadow \
	starship \
	tmux \
	unzip \
	stow \
	zsh


# Create the "home" folder
RUN mkdir -p $WORKDIR
# RUN nix-env -iA \
# 	nixpkgs.bash \
# 	nixpkgs.bat \
# 	nixpkgs.cargo \
# 	nixpkgs.curl \
# 	nixpkgs.fd \
# 	nixpkgs.fzf \
# 	nixpkgs.gcc \
# 	nixpkgs.gnumake \
# 	nixpkgs.libgcc \
# 	nixpkgs.musl \
# 	nixpkgs.lazygit \
# 	nixpkgs.neovim \	
# 	# NodeJS is required for Mason plugin
# 	nixpkgs.nodejs_22 \
# 	nixpkgs.ripgrep \
# 	nixpkgs.rustc \
# 	nixpkgs.starship \
# 	nixpkgs.stow \
# 	nixpkgs.tmux \
# 	nixpkgs.yazi \
# 	nixpkgs.zig \ 
# 	nixpkgs.zsh

RUN mkdir -p $HOME/dotfiles && \
	git clone https://github.com/hsteinshiromoto/dotfiles.linux.git $HOME/dotfiles
RUN cd $HOME/dotfiles && stow .

RUN git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm && \
	~/.tmux/plugins/tpm/bin/install_plugins

# The following npm packaged is required by tree-sitter
RUN cargo install tree-sitter-cli | sh -s -- -y
RUN nvim --headless "+Lazy! sync" +qa

SHELL ["zsh", "-c"]

EXPOSE 6666
CMD [ "nvim", "--headless", "--listen",  "0.0.0.0:6666" ]
