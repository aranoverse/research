- https://learnblockchain.cn/article/5376
- https://docs.ordinals.com/overview.html
- https://www.youtube.com/watch?v=RpoDtNwWSBo
- https://www.btcstudy.org/2022/08/15/what-are-partially-signed-bitcoin-transactions-psbts/
- https://orders-exchange.gitbook.io/orders/overview/what-is-orders
- [Taproot tx](https://mp.weixin.qq.com/s/SYpcLQy_TKuqDtxzSRwd0Q)
- [Taproot assets](https://mp.weixin.qq.com/s/amvE8zg_IdDhmUrxsQwN_g)
- [MAST](https://mp.weixin.qq.com/s/qA9AJ08KxRU9qhWngJ4OkA)
- [隔离见证](https://mp.weixin.qq.com/s/6bsOD-SZIVj3hNXzvLFQsQ)

# local btc regtest ord steps
1. btc.conf
```conf 
[regtest]
dbcache=10240
txindex=1
upnp=1
daemon=1
server=1
rest=1
rpcallowip=0.0.0.0/0

#local testnet
fallbackfee=0.0001
 ```
2. btcd regtest
```shell
bitcoind -deamon -regtest
```

3. create wallet
```shell
bitcoin-cli -regtest createwallet walletname
bitcoin-cli -regtest loadwallet walletname
```
4. retrieve test btc and generate block
```shell
bitcoin-cli -regtest -rpcwallet={walletname} -generate 100
```
5. drip btc to ord wallet after launch ord
```shell
bitcoin-cli -regtest -rpcwallet={walletname}  sendtoaddress {ord_wallet_addr} 1
```
