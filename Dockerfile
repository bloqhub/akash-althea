FROM golang:1.15-alpine AS build-env
ENV PACKAGES curl make git libc-dev bash gcc linux-headers eudev-dev python3
WORKDIR /src
COPY . .
RUN apk add --no-cache $PACKAGES && \
make install

FROM alpine:3.5
ARG password
RUN apk --update add --no-cache openssh bash supervisor ca-certificates \
  && sed -i s/#PermitRootLogin.*/PermitRootLogin\ yes/ /etc/ssh/sshd_config \
  && echo "root:$password" | chpasswd \
  && rm -rf /var/cache/apk/*
RUN sed -ie 's/#Port 22/Port 2242/g' /etc/ssh/sshd_config
RUN /usr/bin/ssh-keygen -A
RUN ssh-keygen -t rsa -b 4096 -f  /etc/ssh/ssh_host_key
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile
EXPOSE 2242 22656 26657
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY --from=build-env /go/bin/althea /usr/bin/althea
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
