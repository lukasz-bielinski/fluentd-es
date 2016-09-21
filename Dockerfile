FROM oberthur/docker-ubuntu:16.04

ENV METADATA_FILTER=0.25.3
ENV FLUENT_ELASTICSEARCH=1.7.0

#RUN ulimit -n 65536
RUN echo "nameserver 8.8.8.8" >> /etc/resolv.conf

RUN locale-gen en_US.UTF-8

ENV DEBIAN_FRONTEND=noninteractive \
LANGUAGE=en_US.en \
LANG=en_US.UTF-8 \
LC_ALL=en_US.UTF-8


RUN echo 'APT::Install-Recommends "0"; \n\
          APT::Get::Assume-Yes "true"; \n\
          APT::Install-Suggests "0";' > /etc/apt/apt.conf \ && apt-get update


RUN apt-get install -y -q --no-install-recommends \
   curl ca-certificates make g++ sudo bash

 # Install Fluentd.
RUN /usr/bin/curl -sSL https://toolbelt.treasuredata.com/sh/install-ubuntu-xenial-td-agent2.sh | sh

 # Change the default user and group to root.
 # Needed to allow access to /var/log/docker/... files.
RUN sed -i -e "s/USER=td-agent/USER=root/" -e "s/GROUP=td-agent/GROUP=root/" /etc/init.d/td-agent

 # Install the Elasticsearch Fluentd plug-in.
 # http://docs.fluentd.org/articles/plugin-management
RUN td-agent-gem install --no-document fluent-plugin-kubernetes_metadata_filter -v $METADATA_FILTER
RUN td-agent-gem install --no-document fluent-plugin-elasticsearch -v $FLUENT_ELASTICSEARCH

 # Remove docs and postgres references
RUN rm -rf /opt/td-agent/embedded/share/doc \
   /opt/td-agent/embedded/share/gtk-doc \
   /opt/td-agent/embedded/lib/postgresql \
   /opt/td-agent/embedded/bin/postgres \
   /opt/td-agent/embedded/share/postgresql

RUN apt-get remove -y make g++
RUN apt-get autoremove -y
RUN apt-get clean -y

RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


ENTRYPOINT ["td-agent"]
