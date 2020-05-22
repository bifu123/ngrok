#!/bin/sh
echo "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
echo "&&                             &&"
echo "&&     适用于ubuntu18.04        &&"
echo "&&       QQ:415135222          &&"
echo "&&        2020-05-08           &&"
echo "&&                             &&"
echo "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
echo "                                 "

#使用示例：wget ftp://1.207.63.31:2121/pub/tools/linux/ngrok.sh && sh ./ngrok.sh

echo "请设置ngrok Server的域名"
read n_domain

echo "请设置http服务端口"
read n_http_port

echo "请设置https服务端口"
read n_https_port

echo "请设置ngrok安装目录"
read n_path


#刷新软件源
sudo apt-get update

#安装go语言和git
sudo apt-get install build-essential golang mercurial git -y

#下载ngrok
if [ ! -d "$n_path" ]; then
    sudo mkdir -p $n_path
fi
cd $n_path
sudo chmod 777 -R ./
sudo rm -rf ./*

sudo git clone https://github.com/tutumcloud/ngrok.git ngrok
# sudo wget ftp://ftp.permit.gov.cn:2121/pub/tools/linux/ngrok.tar.gz
# sudo tar -zxvf ngrok.tar.gz

sudo mv ./ngrok/* ./
sudo rm -rf ./ngrok
sudo chmod 777 -R ./*

#创建证书
NGROK_DOMAIN="$n_domain"
sudo openssl genrsa -out base.key 2048
sudo openssl req -new -x509 -nodes -key base.key -days 10000 -subj "/CN=$NGROK_DOMAIN" -out base.pem
sudo openssl genrsa -out server.key 2048
sudo openssl req -new -key server.key -subj "/CN=$NGROK_DOMAIN" -out server.csr
sudo openssl x509 -req -in server.csr -CA base.pem -CAkey base.key -CAcreateserial -days 10000 -out server.crt

#替换证书
sudo cp base.pem assets/client/tls/ngrokroot.crt

sudo chmod 777 -R ./*
sudo chmod 777 -R ./

#编译服务端和linux客户端
make release-server release-client
#编译windows_64bit客户端
GOOS=windows GOARCH=amd64 make release-client
#编译MAC客户端
GOOS=darwin GOARCH=amd64 make release-client

echo "创建客户端配置文件"
(
sudo cat<<EOF
server_addr: "$n_domain:4443"
trust_host_root_certs: false
tunnels:
#http协议
  http:    
    subdomain: "ngrok"
    proto:
      http: 80
#https协议
  https:
    subdomain: "ssl"
    proto:
      https: 443
#其它TCP协议，只能使用端口转发，不能使用域名
  mssql:
    remote_port: 14331
    proto:
      tcp: 1433
EOF
)>$n_path/bin/windows_amd64/ngrok.cfg

sudo cat>$n_path/bin/windows_amd64/startup.bat<<EOF
@echo on
cd %cd%
#ngrok -proto=tcp 22
#ngrok -config=ngrok.cfg -log=ngrok.log -subdomain=yjc 8080
ngrok -config=ngrok.cfg start http https mssql
EOF
echo "windows客户端文件创建完毕，路径在$n_path/bin/"


echo "创建服务"
sudo cat>./ngrok.service<<EOF
[Unit]
Description=ngrok
After=network.target

[Service]
ExecStart=$n_path/bin/ngrokd -tlsKey=$n_path/server.key -tlsCrt=$n_path/server.crt -domain="$n_domain" -httpAddr=":$n_http_port" -httpsAddr=":$n_https_port"

[Install]
WantedBy=multi-user.target
EOF
sudo mv ./ngrok.service /etc/systemd/system/
sudo chmod a+x /etc/systemd/system/ngrok.service
echo "服务创建完毕，可以sudo systemctl start ngrok.service启动之。手动启动:$n_path/bin/ngrokd -tlsKey=$n_path/server.key -tlsCrt=$n_path/server.crt -domain=\"$n_domain\" -httpAddr=\":$n_http_port\" -httpsAddr=\":$n_https_port\""
#复制到本地
echo "复制到test@1.207.63.31:/home/test/"
#scp -r /opt/ngrok/bin/windows_amd64 test@yourlocalpc:/home/test/
