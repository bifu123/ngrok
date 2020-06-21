#!/bin/sh
echo "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
echo "&&                             &&"
echo "&&     适用于deb/ubuntu         &&"
echo "&&       QQ:415135222          &&"
echo "&&        2020-05-08           &&"
echo "&&                             &&"
echo "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
echo "                                 "

#使用示例：rm -rf ./ngrok_crt.sh && wget ftp://n31.freesky.buzz:2121/pub/tools/linux/ngrok_crt.sh && sh ./ngrok_crt.sh
echo "请务必切换到root执行"
echo "请设置ngrok Server的域名（由cloudfare解析的域名。注意：现在免费域名不再受cloudfare API支持）"
read n_domain

echo "请设置http服务端口"
read n_http_port

echo "请设置https服务端口"
read n_https_port

echo "请设置ngrok安装目录"
read n_path


#刷新软件源
apt-get update

#安装go语言和git
apt-get install build-essential golang mercurial git -y

#下载ngrok
if [ ! -d "$n_path" ]; then
    mkdir -p $n_path
fi
cd $n_path
chmod 777 -R ./
rm -rf ./*

git clone https://github.com/tutumcloud/ngrok.git ngrok
# wget ftp://ftp.permit.gov.cn:2121/pub/tools/linux/ngrok.tar.gz
# tar -zxvf ngrok.tar.gz

mv ./ngrok/* ./
rm -rf ./ngrok
chmod 777 -R ./*

#创建证书
NGROK_DOMAIN="$n_domain"
openssl genrsa -out base.key 2048
openssl req -new -x509 -nodes -key base.key -days 10000 -subj "/CN=$NGROK_DOMAIN" -out base.pem
openssl genrsa -out server.key 2048
openssl req -new -key server.key -subj "/CN=$NGROK_DOMAIN" -out server.csr
openssl x509 -req -in server.csr -CA base.pem -CAkey base.key -CAcreateserial -days 10000 -out server.crt

# echo "请设置ngrok Server的域名（由cloudfare解析的顶级域名。注意：现在免费域名不再受cloudfare API支持）"
# read n_domain
echo "CF_Key ep:  3d0fb11da4b22bd08eac5701a2df11bb9eefd"
read CF_Key
echo "CF_Email"
read CF_Email

apt install curl -y
curl https://get.acme.sh | sh
source ~/.bashrc
#导入CF的API：
export CF_Key=$CF_Key
export CF_Email=$CF_Email
~/.acme.sh/acme.sh --issue --dns dns_cf -d $n_domain -d *.$n_domain -k ec-256
~/.acme.sh/acme.sh --installcert -d $n_domain -d *.$n_domain --fullchainpath ./$n_domain.crt --keypath ./$n_domain.key --ecc
#定期自动更新
~/.acme.sh/acme.sh --upgrade --auto-upgrade
echo "证书申请完成"
ls



#替换证书
#cp base.pem assets/client/tls/ngrokroot.crt
#cp ./$n_domain.crt assets/client/tls/ngrokroot.crt
# cp ./$n_domain.crt ./server.crt
# cp ./$n_domain.key ./server.key
cp ./$n_domain.crt assets/server/tls/snakeoil.crt
cp ./$n_domain.key assets/server/tls/snakeoil.key


chmod 777 -R ./*
chmod 777 -R ./

echo "编译服务端和客户端"
make release-server release-client
#编译windows_64bit客户端,如果是32位，GOARCH=386
GOOS=windows GOARCH=amd64 make release-client
#编译MAC客户端
GOOS=darwin GOARCH=amd64 make release-client


echo "创建客户端配置文件"
(
cat<<EOF
server_addr: "$n_domain:4443"
trust_host_root_certs: false
tunnels:
#http协议
  http:    
    subdomain: "www"
    proto:
      http: 80
#https协议
  https:
    subdomain: "www"
    proto:
      https: 443
#其它TCP协议，只能使用端口转发，不能使用域名
  mssql:
    remote_port: 14331
    proto:
      tcp: 1433
EOF
)>$n_path/bin/windows_amd64/ngrok.cfg

cat>$n_path/bin/windows_amd64/startup.bat<<EOF
@echo on
cd %cd%
#ngrok -proto=tcp 22
#ngrok -config=ngrok.cfg -log=ngrok.log -subdomain=yjc 8080
ngrok -config=ngrok.cfg start http https mssql
EOF
echo "windows客户端文件创建完毕，路径在$n_path/bin/"

#创建linux客户端
mkdir $n_path/bin/linux-client
cp $n_path/bin/windows_amd64/ngrok.cfg $n_path/bin/ngrok $n_path/bin/linux-client/
(
cat<<EOF
#!/bin/sh
ngrok -config=ngrok.cfg start http https mssql
EOF
)>$n_path/bin/linux-client/startup.sh

echo "创建服务"
cat>./ngrok.service<<EOF
[Unit]
Description=ngrok
After=network.target

[Service]
ExecStart=$n_path/bin/ngrokd -tlsKey=$n_path/server.key -tlsCrt=$n_path/server.crt -domain="$n_domain" -httpAddr=":$n_http_port" -httpsAddr=":$n_https_port"

[Install]
WantedBy=multi-user.target
EOF
mv ./ngrok.service /etc/systemd/system/
chmod a+x /etc/systemd/system/ngrok.service
echo "服务创建完毕，可以systemctl start ngrok.service启动之。手动启动:$n_path/bin/ngrokd  -domain=\"$n_domain\" -httpAddr=\":$n_http_port\" -httpsAddr=\":$n_https_port\""
#复制到本地
echo "请把客户端复制到本地，即可使用了"
#scp -r /opt/ngrok/bin/windows_amd64 test@localip:/home/test/
