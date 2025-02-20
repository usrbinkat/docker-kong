FROM centos:7
LABEL maintainer="Kong <support@konghq.com>"

ARG ASSET=ce
ENV ASSET $ASSET

ARG EE_PORTS

COPY kong.rpm /tmp/kong.rpm

ARG KONG_VERSION=2.4.1
ENV KONG_VERSION $KONG_VERSION

ARG KONG_SHA256="b8083a6c268f69865e66a8d504fcdacab49ba36a4194ccfc9737d65e6863c30a"

RUN set -ex; \
  if [ "$ASSET" = "ce" ] ; then \
  curl -fL https://download.konghq.com/gateway-${KONG_VERSION%%.*}.x-centos-7/Packages/k/kong-$KONG_VERSION.el7.amd64.rpm -o /tmp/kong.rpm \
    && echo "$KONG_SHA256  /tmp/kong.rpm" | sha256sum -c -; \
  fi; \
  yum install -y -q unzip shadow-utils git \
  && yum clean all -q \
  && rm -fr /var/cache/yum/* /tmp/yum_save*.yumtx /root/.pki \
  # Please update the centos install docs if the below line is changed so that
  # end users can properly install Kong along with its required dependencies
  # and that our CI does not diverge from our docs.
  && yum install -y /tmp/kong.rpm \
  && yum clean all \
  && rm /tmp/kong.rpm \
  && chown kong:0 /usr/local/bin/kong \
  && chown -R kong:0 /usr/local/kong && \
  if [ "$ASSET" = "ce" ] ; then \
    kong version ; \
  fi;

COPY docker-entrypoint.sh /docker-entrypoint.sh

USER kong

ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 8000 8443 8001 8444 $EE_PORTS

STOPSIGNAL SIGQUIT

HEALTHCHECK --interval=10s --timeout=10s --retries=10 CMD kong health

CMD ["kong", "docker-start"]
