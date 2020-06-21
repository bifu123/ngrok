# ngrok
# One Key stup ngrok on ubuntu18.04
一键安装ngrok服务端，安装完成会有提示<br>
## 使用自签证书
rm -rf ngrok.sh && wget https://github.com/bifu123/ngrok/blob/master/ngrok.sh && chmod +x ./ngrok.sh && sh ./ngrok.sh<br>
## 使用CloudFare证书
rm -rf ngrok_srt.sh && wget https://github.com/bifu123/ngrok/blob/master/ngrok_crt.sh && chmod +x ./ngrok_srt.sh && sh ./ngrok_srt.sh<br>
