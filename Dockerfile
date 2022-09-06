FROM oraclelinux:8.6
LABEL description="SSH Server image"


# External Arguments
# ------------------
ARG USER=resu
ARG PASSWORD=drowssap
ARG TIMEZONE=Europe/Paris
ARG DEPLOY_DIR=/usr/local/deploy


# Environment Variables
# ---------------------
# Ref: https://github.com/snapcore/snapcraft/blob/master/Dockerfile
ENV LC_ALL C.UTF-8


# Copy Configurations & Scripts (without apply)
# ---------------------------------------------
COPY deploy $DEPLOY_DIR


# Change Timezone
# ---------------
# Ref: https://ma.ttias.be/changing-the-time-and-timezone-settings-on-centos-or-rhel/
RUN mv -f /etc/localtime /etc/localtime.backup
RUN ln -s /usr/share/zoneinfo/$TIMEZONE /etc/localtime


# Init Script
# -----------
RUN cp $DEPLOY_DIR/usr/local/bin/init /usr/local/bin/init
RUN chmod 500 /usr/local/bin/init


# One-time User Setup
# -------------------
RUN cp $DEPLOY_DIR/usr/local/bin/usersetup /usr/local/bin/usersetup
RUN chmod 500 /usr/local/bin/usersetup


# Remove Nologin Service Fix
# --------------------------
# Handle issues with Nologin after boot.
# Ref: https://unix.stackexchange.com/questions/487742/system-is-booting-up-unprivileged-users-are-not-permitted-to-log-in-yet
RUN cp $DEPLOY_DIR/usr/local/bin/remove-nologin /usr/local/bin/remove-nologin
RUN chmod 500 /usr/local/bin/remove-nologin


# Install Packages - Init
# -----------------------
RUN dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
RUN dnf update -y
RUN dnf install -y epel-release


# Install Packages - Tools
# ------------------------
RUN dnf update -y && dnf install -y \
    bzip2 \
    ca-certificates \
    cabextract \
    fontconfig \
    git \
    glibc-langpack-en \
    gzip \
    hostname \
    htop \
    mc \
    netcat \
    net-tools \
    openssh-server \
    openssh-clients \
    passwd \
    redhat-lsb \
    rsync \
    sudo \
    supervisor \
    tar \
    tcpdump \
    telnet \
    tree \
    unzip \
    wget \
    xdg-utils \
    xz \
    zip


# Copy Custom User Settings
# -------------------------
RUN cp -r $DEPLOY_DIR/etc/skel/. /etc/skel


# Copy Root User Settings
# -------------------------
RUN cp -r $DEPLOY_DIR/root/.bashrc /root/.bashrc
RUN chmod 600 /root/.bashrc


# Add User to System
# ------------------
# Create user and set password. Add to wheel for sudo use.
RUN useradd -m -s /bin/bash $USER
RUN echo "$USER:$PASSWORD" | chpasswd
RUN usermod -aG wheel $USER


# Install Gosu
# ------------
# Sudo Alternative for Docker: simple tool grown out of the simple fact that su and sudo
# have very strange and often annoying TTY and signal-forwarding behavior.
RUN if [[ -n "$GOSU_VERSION" ]]; then \
		gpg --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 && \
		curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.14/gosu-amd64" && \
		curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/1.14/gosu-amd64.asc" && \
		gpg --verify /usr/local/bin/gosu.asc && \
		rm -f /usr/local/bin/gosu.asc && \
		rm -rf /root/.gnupg/ && \
		chmod +x /usr/local/bin/gosu && \
		gosu nobody true; \
    fi


# Copy Supervisord Script
# ------------------------
RUN mkdir /etc/supervisord
RUN cp $DEPLOY_DIR/etc/supervisord/supervisord.conf /etc/supervisord/supervisord.conf


# Expose Ports
# ------------
EXPOSE 22


# Command on Start
# ----------------
CMD [ "sh", "-c", "/usr/local/bin/init && exec supervisord -c /etc/supervisord/supervisord.conf" ]
