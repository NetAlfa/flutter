FROM ghcr.io/cirruslabs/flutter:stable

# Install system dependencies, Git, GitHub CLI, and OpenSSH Server
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    openssh-server \
    sudo \
    && mkdir -p /usr/share/keyrings \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Configure SSH Server
RUN mkdir /var/run/sshd
# Set a default password for testing (change or use SSH keys for production)
RUN echo 'root:flutterpass' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise, user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

EXPOSE 22

# Start SSH server in the foreground
CMD ["/usr/sbin/sshd", "-D"]

