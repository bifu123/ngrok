# ngrok
# One Key stup ngrok on ubuntu18.04
一键安装ngrok服务端，安装完成会有提示<br>
## 使用自签证书
rm -rf ./ngrok/ && git clone https://github.com/bifu123/ngrok.git && chmod +x ./ngrok/ngrok.sh && sh ./ngrok/ngrok.sh<br>
## 使用CloudFare证书
rm -rf ./ngrok/ && git clone https://github.com/bifu123/ngrok.git && chmod +x ./ngrok/ngrok_crt.sh && sh ./ngrok/ngrok_crt.sh<br>
