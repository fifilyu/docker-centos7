FROM centos:7

ENV TZ Asia/Shanghai
ENV LANG en_US.UTF-8

##############################################
# buildx有缓存，注意判断目录或文件是否已经存在
##############################################

####################
# 设置YUM
####################
RUN grep '*.i386 *.i586 *.i686' /etc/yum.conf || echo "exclude=*.i386 *.i586 *.i686" >> /etc/yum.conf
RUN ulimit -n 1024 && yum install -y epel-release
RUN ulimit -n 1024 && yum makecache

####################
# 更新系统软件包
####################
RUN ulimit -n 1024 && yum update -y

####################
# 中文环境支持
####################
RUN ulimit -n 1024 && yum install -y wqy-microhei-fonts wqy-zenhei-fonts wqy-unibit-fonts

####################
# 安装常用软件包
####################
RUN ulimit -n 1024 && yum install -y iproute rsync yum-utils tree pwgen vim-enhanced wget curl screen bzip2 tcpdump unzip tar xz bash-completion-extras telnet chrony sudo strace openssh-server openssh-clients mlocate

RUN grep 'set fencs=utf-8,gbk' /etc/vimrc || echo 'set fencs=utf-8,gbk' >>/etc/vimrc

####################
# 设置文件句柄
####################
RUN grep '*               soft   nofile            65535' /etc/security/limits.conf || echo "*               soft   nofile            65535" >> /etc/security/limits.conf
RUN grep '*               hard   nofile            65535' /etc/security/limits.conf || echo "*               hard   nofile            65535" >> /etc/security/limits.conf

####################
# 关闭SELINUX
####################
RUN echo SELINUX=disabled>/etc/selinux/config
RUN echo SELINUXTYPE=targeted>>/etc/selinux/config

####################
# 配置SSH
####################
RUN mkdir -p /root/.ssh
RUN touch /root/.ssh/authorized_keys
RUN chmod 600 /root/.ssh/authorized_keys
COPY file/etc/ssh/sshd_config /etc/ssh/sshd_config

RUN ssh-keygen -t rsa -b 2048 -N '' -f /etc/ssh/ssh_host_rsa_key
RUN ssh-keygen -t ecdsa -b 256 -N '' -f /etc/ssh/ssh_host_ecdsa_key
RUN ssh-keygen -t ed25519 -b 256 -N '' -f /etc/ssh/ssh_host_ed25519_key

####################
# 安装Python3.11
####################
RUN ulimit -n 1024 && yum install -y tcl tk xz zlib

###########################
## 安装依赖：OpenSSL-1.1.1n
###########################
COPY file/usr/local/openssl-1.1.1n /usr/local/openssl-1.1.1n
RUN echo '/usr/local/openssl-1.1.1n/lib' > /etc/ld.so.conf.d/openssl-1.1.1n.conf
RUN ldconfig
RUN ldconfig -p | grep openssl-1.1.1n 

###########################
## 安装Python311
###########################
COPY file/usr/local/python-3.11.5/ /usr/local/python-3.11.5/
WORKDIR /usr/local
RUN test -L python3 || ln -s python-3.11.5 python3

ARG py_bin_dir=/usr/local/python3/bin
RUN echo "export PATH=${py_bin_dir}:\${PATH}" > /etc/profile.d/python3.sh

WORKDIR ${py_bin_dir}
RUN test -L pip311 || ln -v -s pip3 pip311
RUN test -L python311 || ln -v -s python3 python311

RUN ./pip311 install --root-user-action=ignore -U pip

####################
# 安装常用编辑工具
####################
RUN ./pip311 install --root-user-action=ignore -U yq toml-cli

RUN wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -O /usr/local/bin/jq
RUN chmod 755 /usr/local/bin/jq

RUN ulimit -n 1024 && yum install -y xmlstarlet crudini

####################
# 清理
####################
RUN rm -f /root/anaconda-ks.cfg
RUN ulimit -n 1024 && yum clean all

####################
# 设置开机启动
####################
COPY file/usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod 755 /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

WORKDIR /root

EXPOSE 22
