
# ---
# Build arguments
# ---
ARG DOCKER_PARENT_IMAGE=hsteinshiromoto/alpix:latest
FROM --platform=linux/amd64 $DOCKER_PARENT_IMAGE

# NB: Arguments should come after FROM otherwise they're deleted
ARG BUILD_DATE
ARG USER=user

# ---
# Enviroment variables
# ---
ENV LANG=C.UTF-8 \
	LC_ALL=C.UTF-8
ENV TZ=Australia/Sydney
ENV SHELL=/bin/bash
ENV HOME=/home/$USER
ENV WORKDIR=$HOME

SHELL ["/bin/bash", "-c"]

# Set container time zone
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

LABEL org.label-schema.build-date=$BUILD_DATE \
	maintainer="hsteinshiromoto@gmail.com"

# Create the "home" folder
RUN mkdir -p $WORKDIR
RUN nix-env -iA \
	nixpkgs.cargo \
	nixpkgs.curl \
	nixpkgs.fd \
	nixpkgs.fzf \
	nixpkgs.lazygit \
	nixpkgs.neovim \	
	nixpkgs.ripgrep \
	nixpkgs.stow \
	nixpkgs.tmux \
	nixpkgs.zsh

RUN mkdir -p $HOME/dotfiles && \
	git clone https://github.com/hsteinshiromoto/dotfiles.linux.git $HOME/dotfiles
RUN cd $HOME/dotfiles && stow .

RUN git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm && \
	~/.tmux/plugins/tpm/bin/install_plugins

RUN nvim --headless "+Lazy! sync" +qa

EXPOSE 6666
CMD [ "nvim", "--headless", "--listen",  "0.0.0.0:6666" ]
