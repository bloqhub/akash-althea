Сборка docker образа althea для akash
```
git clone https://github.com/althea-net/althea-chain.git
git clone https://github.com/bloqhub/akash-althea.git
cp ./akash-althea/Dockerfile ./althea-chain/
cp ./akash-althea/supervisord.conf ./althea-chain/
cd ./althea-chain/
docker build -t bloqhub/althea-ssh:0.2.3 --build-arg password=sshpassword ./
```
sshpassword - пароль ssh для root аккаунта
и размещаем образ на dockerhub
```
docker push bloqhub/althea-ssh:0.2.3
```
