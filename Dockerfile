# ---
# Build arguments
# ---
ARG DOCKER_PARENT_IMAGE=alpine:3.20.3
FROM $DOCKER_PARENT_IMAGE

# NB: Arguments should come after FROM otherwise they're deleted
ARG BUILD_DATE
ARG USER=user
ARG PYTHON_VERSION=3.13

# ---
# Enviroment variables
# ---
ENV LANG=C.UTF-8 \
	LC_ALL=C.UTF-8
ENV TZ=Australia/Sydney
ENV PATH="/nix/var/nix/profiles/default/bin:$PATH"
ENV HOME=/home/$USER

# Set container time zone
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

LABEL org.label-schema.build-date=$BUILD_DATE \
	maintainer="hsteinshiromoto@gmail.com"

# Create the "home" folder
RUN mkdir -p $HOME/workspace

# ---
# Install Neovim packages
# ---
RUN apk add bash

ENV SHELL=/bin/bash

SHELL ["/bin/bash", "-c"]

RUN apk --no-cache add \
	autoconf \
	automake \
	bash \
	bat \
	build-base \
	cargo \
	cmake \
	curl \
	coreutils \
	curl \
	fd \
	fontconfig \
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
	stow \
	tmux \
	unzip \
	xz \
	wget \
	zsh

COPY bin/get_nix.sh /usr/local/bin
RUN chmod +x /usr/local/bin/get_nix.sh && bash /usr/local/bin/get_nix.sh


# ---
# Install Pyenv
# ---
# Install OS dependencies to build Python
RUN apk add openssl-dev zlib-dev readline-dev bzip2-dev
RUN curl https://pyenv.run | bash

ENV PYENV_ROOT="${HOME}/.pyenv"
ENV PATH="${PYENV_ROOT}/shims:${PYENV_ROOT}/bin:${PATH}"

RUN pyenv install $PYTHON_VERSION:latest && pyenv global $PYTHON_VERSION

# ---
# Install Poetry
# ---
RUN curl -sSL https://install.python-poetry.org | python3 -

ENV PATH="${HOME}/.local/bin:${PATH}"

RUN poetry self add poetry-plugin-up

# ---
# Clone and set dotfiles
# ---
RUN mkdir -p $HOME/dotfiles && \
	git clone https://github.com/hsteinshiromoto/dotfiles.linux.git $HOME/dotfiles
RUN cd $HOME/dotfiles && stow .

# ---
# Install JetBrains Mono Nerd Font
# ---
RUN wget -P ~/.local/share/fonts https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/JetBrainsMono.zip \
	&& cd ~/.local/share/fonts \
	&& unzip JetBrainsMono.zip \
	&& rm JetBrainsMono.zip \
	&& fc-cache -fv

# ---
# Install tmux plugins
# ---
RUN git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm && \
	~/.tmux/plugins/tpm/bin/install_plugins

# The following npm packaged is required by tree-sitter
RUN cargo install tree-sitter-cli | sh -s -- -y
RUN nvim --headless "+Lazy! sync" +qa

SHELL ["zsh", "-c"]

EXPOSE 6666
CMD [ "nvim", "--headless", "--listen",  "0.0.0.0:6666" ]
