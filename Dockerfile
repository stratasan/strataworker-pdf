FROM ubuntu:trusty
#latest is LTS
ENV DEBIAN_FRONTEND noninteractive
ENV GOSU_VERSION 1.10
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8


RUN sed 's/main$/main universe/' -i /etc/apt/sources.list
RUN apt-get update

# Download and install wkhtmltopdf
RUN apt-get install -y build-essential xorg libssl-dev libxrender-dev wget gdebi software-properties-common
RUN wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.1/wkhtmltox-0.12.1_linux-trusty-amd64.deb
RUN gdebi --n wkhtmltox-0.12.1_linux-trusty-amd64.deb

RUN wget -qO- https://deb.nodesource.com/setup_9.x | bash -

# App related packages
RUN apt-get install -y \
    python3 \
    python3-dev \
    python3-pip \
    curl \
    jq \
    git && \
  pip3 install -U pipenv && \
  apt-get remove -y python3-pip python3-six && \
  apt-get autoremove -y

# Install gosu so that the container user is a non-root user
RUN gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
    && curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
    && gpg --verify /usr/local/bin/gosu.asc \
    && rm /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

WORKDIR /app

COPY Pipfile /app
COPY Pipfile.lock /app
RUN pipenv install --deploy --system

COPY . /app
