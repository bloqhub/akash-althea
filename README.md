Установка и старт Althea ноды в akash

Перед установкой akash определяем переменные среды
```
AKASH_NET="https://raw.githubusercontent.com/ovrclk/net/master/mainnet"
AKASH_VERSION="$(curl -s "$AKASH_NET/version.txt")"
export AKASH_CHAIN_ID="$(curl -s "$AKASH_NET/chain-id.txt")"
export AKASH_NODE="$(curl -s "$AKASH_NET/rpc-nodes.txt" | shuf -n 1)"
```
Устанавливаем akash (Linux)
```
curl https://raw.githubusercontent.com/ovrclk/akash/master/godownloader.sh | sh -s -- "v$AKASH_VERSION"
cp ./bin/akash /usr/local/bin/
```

Создаем кошелек
```
akash keys add default
- name: default
type: local
address: akash1ra5sxladp3wv5ej9p8qx5y227zhya8sfqrdw8h
pubkey: akashpub1addwnpepqtdc60d8yfayuq6340waga494w9uknm2y0jpl37zyzj8wx6fa2cmq06p39e
mnemonic: ""
threshold: 0
pubkeys: []

**Important** write this mnemonic phrase in a safe place.
It is the only way to recover your account if you ever forget your password.

wood system walnut transfer square soon into very spatial note grief cliff dismiss ability sun exist twin tower marine crazy design gate lift bulk
```
Сохраняем мнемоническую фразу, без нее восстановление кошелька будет невозможно.

Определяем переменные с именем и адресом кошелька
```
export AKASH_ACCOUNT_ADDRESS="$(akash keys show default -a)"
export AKASH_KEY_NAME="default"
```
Для продолжения необходимо преборести АКТ токены - https://akash.network/token

Проверяем баланс 
```
akash --node "$AKASH_NODE" query bank balances "$AKASH_ACCOUNT_ADDRESS"
```
Создаем сертификат
```
akash tx cert create client --from=$AKASH_KEY_NAME --chain-id $AKASH_CHAIN_ID --node $AKASH_NODE --fees 200uakt -y
```
На этом этапе установку akash можно считать завершенной

Разворачиваем нашу конфигурацию с образом althea
Создаем кофигурационный файл deploy.yml
```
cat > deploy.yml <<EOF
---
version: "2.0"

services:
  althea:
    image: bloqhub/althea-ssh:0.2.3
    expose:
      - port: 22656
        as: 22656
        proto: tcp
        to:
          - global: true
      - port: 2242
        as: 2242
        proto: tcp
        to:
          - global: true
      - port: 26657
        as: 80
        proto: tcp
        to:
          - global: true


profiles:
  compute:
    althea:
      resources:
        cpu:
          units: 0.1
        memory:
          size: 512Mi
        storage:
          size: 512Mi
  placement:
    akash:
      attributes:
        host: akash
      signedBy:
        anyOf:
          - "akash1365yvmc4s7awdyj3n2sav7xfx76adc6dnmlx63"
      pricing:
        althea:
          denom: uakt
          amount: 100

deployment:
  althea:
    akash:
      profile: althea
      count: 1

EOF
```
Важно! адрес "akash1365yvmc4s7awdyj3n2sav7xfx76adc6dnmlx63" оставляем неизменным - это адрес escrow аккаунта.
Параметры cpu, memory и size в данной конфиграции установленны  близкими к минимальным, в реальном использовании необходимо
увеличить их

Развораяиваем нашу конфигурацию
```
akash tx deployment create deploy.yml --from $AKASH_KEY_NAME --node $AKASH_NODE --chain-id $AKASH_CHAIN_ID --fees 200uakt -b sync -y

{"height":"0","txhash":"05CBBC9ACBD1F51AF5B0D254E2BFD56B1ACA42819E5BABEEC5086947625E45D4","codespace":"","code":0,"data":"","raw_log":"[]","logs":[],"info":"","gas_wanted":"0","gas_used":"0","tx":
null,"timestamp":""}
```
проверяем статус нашей установки
```
akash q tx 05CBBC9ACBD1F51AF5B0D254E2BFD56B1ACA42819E5BABEEC5086947625E45D4 --node=$AKASH_NODE
"05CBBC9ACBD1F51AF5B0D254E2BFD56B1ACA42819E5BABEEC5086947625E45D4" получаем из вывода предыдущей команды
```
в выводе этой команды нас интересует значение dseq
Определяем переменные
```
export AKASH_DSEQ=2252882
export AKASH_GSEQ=1
export AKASH_OSEQ=1
```
проверяем статус развертывания
```
akash query deployment get --owner $AKASH_ACCOUNT_ADDRESS --node $AKASH_NODE --dseq $AKASH_DSEQ
```
и определяем ставки которые можно использовать для нашей конфигурации
```
akash query market bid list --owner=$AKASH_ACCOUNT_ADDRESS --node $AKASH_NODE --dseq $AKASH_DSEQ
```
в списке возвращвемом командой выбираем провайдера
и присвваем переменной его адрес
```
export AKASH_PROVIDER=akash14c4ng96vdle6tae8r4hc2w4ujwrshdddtuudk0
```
арендуем выбранного провайдера
```
akash tx market lease create --chain-id $AKASH_CHAIN_ID --node $AKASH_NODE --owner $AKASH_ACCOUNT_ADDRESS --dseq $AKASH_DSEQ --gseq $AKASH_GSEQ --oseq $AKASH_OSEQ --provider
$AKASH_PROVIDER --from $AKASH_KEY_NAME --fees 200uakt -y
```
спустя несколько секунда проверяем статус
```
akash query market lease list — owner $AKASH_ACCOUNT_ADDRESS — node $AKASH_NODE — dseq $AKASH_DSEQ
```
Загружаем манифест для нашего образа
```
akash provider send-manifest deploy.yml --node $AKASH_NODE --dseq $AKASH_DSEQ --provider $AKASH_PROVIDER --from $AKASH_KEY_NAME
```
И получаем данные доступа:
```
akash provider lease-status --node $AKASH_NODE --dseq $AKASH_DSEQ --from $AKASH_KEY_NAME --provider $AKASH_PROVIDER
```
Часть вывода,
```
{
"host": "cluster.provider-0.prod.ams1.akash.pub",
"port": 2242,
"externalPort": 31549,
"proto": "TCP",
"available": 1,
"name": "althea"
},
```
нас интересует host и externalPort
в этом примере мы подключаемся к нашей ноде
```
ssh root@cluster.provider-0.prod.ams1.akash.pub -p 31549
```
пароль задается при создании образа, после первого входа его необходимо сменить
Также можно просмотреть логи нашей ноды:
```
akash provider lease-logs --node "$AKASH_NODE" --dseq "$AKASH_DSEQ" --gseq "$AKASH_GSEQ" --oseq "$AKASH_OSEQ" --provider "$AKASH_PROVIDER" --from "$AKASH_KEY_NAME"
```

