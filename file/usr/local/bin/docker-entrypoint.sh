#!/bin/sh

/sbin/sshd

sleep 1

auth_lock_file=/var/log/docker_init_auth.lock

if [ ! -z "${PUBLIC_STR}" ]; then
    if [ -f ${auth_lock_file} ]; then
        echo "`date "+%Y-%m-%d %H:%M:%S"` [信息] 跳过添加公钥"
    else
        echo "${PUBLIC_STR}" >> /root/.ssh/authorized_keys

        if [ $? -eq 0 ]; then
            echo "`date "+%Y-%m-%d %H:%M:%S"` [信息] 公钥添加成功"
            echo `date "+%Y-%m-%d %H:%M:%S"` > ${auth_lock_file}
        else
            echo "`date "+%Y-%m-%d %H:%M:%S"` [错误] 公钥添加失败"
            exit 1
        fi
    fi
fi

pw=$(pwgen -1 20)
echo "$(date +"%Y-%m-%d %H:%M:%S") [信息] Root用户密码：${pw}"
echo "root:${pw}" | chpasswd

# 保持前台运行，不退出
while true
do
    sleep 3600
done

