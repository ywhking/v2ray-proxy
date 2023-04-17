#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "usage: install-v2rayvpn <ipaddress> <v2rayid>"
    exit 1
fi

#####################################################
# v2ray 服务
#####################################################

#下载并安装 v2ray 服务

#检测服务是否存在
if systemctl list-unit-files | grep "v2ray.service" > /dev/null; then
  echo "v2ray 服务已存在!"
else
  echo "开始安装 v2ray 服务 ......"
  curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh -o install-release.sh
  if [ ! -e "install-release.sh" ]; then
      echo "下载安装脚本失败！"
      exit 1
  fi
  chmod +x ./install-release.sh
  ./install-release.sh
  # 检查服务是否安装成功
  if systemctl list-unit-files | grep "v2ray.service" > /dev/null; then
    echo "v2ray 服务安装成功!"  
  else
    echo "v2ray 服务安装失败！"
    exit 1
  fi
fi

#配置 v2ray 服务
old_id="0-0-0-0-0"
new_id=$2
cp -f v2ray.conf /usr/local/etc/v2ray/config.json
# 修改ID
sed -i "s/$old_id/$new_id/g" /usr/local/etc/v2ray/config.json

#启动 v2ray 服务
systemctl enable v2ray
systemctl restart v2ray

if systemctl status v2ray.service | grep "active (running)" > /dev/null;then
    echo "v2ray 服务启动成功！"
else
    echo "v2ray 服务启动失败！"
    exit 1
fi


#####################################################
# nginx 服务
#####################################################

#安装 nginx 服务
if systemctl list-unit-files | grep "nginx.service" > /dev/null; then
  echo "nginx 服务已存在!"
else
  echo "开始安装 nginx 服务 ......"
  apt install -y nginx
  # 检查服务是否安装成功
  if systemctl list-unit-files | grep "nginx.service" > /dev/null; then
    echo "nginx 服务安装成功!"  
  else
    echo "nginx 服务安装失败！"
    exit 1
  fi
fi

#配置 nginx 服务
old_ip="0.0.0.0"
new_ip=$1

#创建服务端自签名证书
mkdir -p /etc/nginx/certs
cp -f cert.conf /etc/nginx/certs/cert.conf
sed -i "s/$old_ip/$new_ip/g" /etc/nginx/certs/cert.conf
openssl req -new -config cert.conf -out /etc/nginx/certs/v2ray.csr -keyout /etc/nginx/certs/v2ray.key
openssl x509 -req -days 365 -in /etc/nginx/certs/v2ray.csr -signkey /etc/nginx/certs/v2ray.key -out /etc/nginx/certs/v2ray.crt

#拷贝并修改nginx配置文件
cp nginx-v2ray.conf /etc/nginx/sites-available/v2ray
sed -i "s/$old_ip/$new_ip/g" /etc/nginx/sites-available/v2ray
cp /etc/nginx/sites-available/v2ray /etc/nginx/sites-enabled/v2ray


#启动 nginx 服务
systemctl enable nginx
systemctl restart nginx

if systemctl status nginx.service | grep "active (running)" > /dev/null;then
    echo "nginx 服务启动成功！"
else    
    echo "nginx 服务启动失败！"
    exit 1
fi


