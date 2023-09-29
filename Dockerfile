FROM centos:7

ENV TZ Asia/Shanghai
ENV LANG en_US.UTF-8

####################
# 设置YUM
####################
RUN echo "exclude=*.i386 *.i586 *.i686" >> /etc/yum.conf
RUN ulimit -n 1024 && yum install -y epel-release
RUN ulimit -n 1024 && yum makecache

####################
# 更新系统软件包
####################
RUN ulimit -n 1024 && yum update -y

####################
# 安装常用软件包
####################
RUN ulimit -n 1024 && yum install -y iproute rsync yum-utils tree pwgen vim-enhanced wget curl screen bzip2 tcpdump unzip tar xz bash-completion-extras telnet chrony sudo strace openssh-server openssh-clients mlocate

RUN echo set fencs=utf-8,gbk >>/etc/vimrc

####################
# 设置文件句柄
####################
RUN echo "*               soft   nofile            65535" >> /etc/security/limits.conf
RUN echo "*               hard   nofile            65535" >> /etc/security/limits.conf

####################
# 关闭SELINUX
####################
RUN echo SELINUX=disabled>/etc/selinux/config
RUN echo SELINUXTYPE=targeted>>/etc/selinux/config

####################
# 配置SSH
####################
RUN mkdir /root/.ssh
RUN touch /root/.ssh/authorized_keys
RUN chmod 600 /root/.ssh/authorized_keys
COPY file/etc/ssh/sshd_config /etc/ssh/sshd_config

RUN ssh-keygen -t rsa -b 2048 -N '' -f /etc/ssh/ssh_host_rsa_key
RUN ssh-keygen -t ecdsa -b 256 -N '' -f /etc/ssh/ssh_host_ecdsa_key
RUN ssh-keygen -t ed25519 -b 256 -N '' -f /etc/ssh/ssh_host_ed25519_key

####################
# 安装Python3.11
####################
RUN ulimit -n 1024 && yum install -y gcc gcc-c++ make libffi-devel bzip2-devel readline-devel ncurses-devel gdbm-devel tkinter tcl-devel tcl libuuid-devel zlib-devel zlib xz-devel xz tk-devel tk openssl-devel sqlite-devel
RUN mkdir -p /tmp/build_tmp

###########################
## 安装依赖：OpenSSL-1.1.1n
###########################
WORKDIR /tmp/build_tmp
RUN wget https://www.openssl.org/source/old/1.1.1/openssl-1.1.1n.tar.gz -O openssl-1.1.1n.tar.gz
RUN tar xf openssl-1.1.1n.tar.gz

WORKDIR /tmp/build_tmp/openssl-1.1.1n
RUN ./config --prefix=/usr/local/openssl-1.1.1n -fPIC
RUN make -j4
# not install document
RUN make install_sw install_ssldirs

RUN echo '/usr/local/openssl-1.1.1n/lib' >> /etc/ld.so.conf
RUN ldconfig
RUN ldconfig -p | grep openssl-1.1.1n

###########################
## 编译安装Python311
###########################
WORKDIR /tmp/build_tmp
RUN wget https://www.python.org/ftp/python/3.11.5/Python-3.11.5.tar.xz -O Python-3.11.5.tar.xz
RUN tar xf Python-3.11.5.tar.xz

WORKDIR /tmp/build_tmp/Python-3.11.5
RUN ./configure --prefix=/usr/local/python-3.11.5 --enable-optimizations --with-openssl=/usr/local/openssl-1.1.1n  --with-ssl-default-suites=openssl --with-ensurepip --enable-loadable-sqlite-extensions
# clean非常重要
RUN make clean && make -j4
RUN make install

ARG py_bin_dir=/usr/local/python-3.11.5/bin
RUN echo "export PATH=${py_bin_dir}:${PATH}" > /etc/profile.d/python3.sh
RUN source /etc/bashrc
WORKDIR ${py_bin_dir}
RUN ln -v -s pip3 pip311
RUN ln -v -s python3 python311

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
RUN ulimit -n 1024 && yum remove -y gcc gcc-c++ make libffi-devel bzip2-devel readline-devel ncurses-devel gdbm-devel tcl-devel libuuid-devel zlib-devel xz-devel tk-devel openssl-devel sqlite-devel
RUN ulimit -n 1024 && yum clean all
RUN rm -rf /tmp/build_tmp

####################
# 设置开机启动
####################
COPY file/usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod 755 /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

WORKDIR /root

EXPOSE 22
