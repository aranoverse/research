# Official site

https://docs.eggs.care/tokenomics

# Tokenomics

Initial Supply: 3,324,324,324,357
Burned: ~931,616,056,878
Current supply: less than ~2,000,000,000,000 (decreasing every block)
Dev has burned all his LP tokens and most of the current liquidity is now community owned.
EGGS started as a LBP on Copper/Fjord to get a fair price and distribution of tokens. Link to LBP here(opens in a new
tab). LBP managed to accrue around 188.78 ETH. Dev exited LBP and used 185 ETH and 175,000,000,000 EGGS to create an
Uniswap V2 pool. Setting the price just below final LBP price. Some time after dev burned all his LP tokens. Most of the
liquidity you see now is community owned.

# Mechanics

EGGS are getting debased every block with a 0.001% rate which is around 7% a day. To compensate a little for this
decrease you can stake your tokens in either Big or Smol vaults and get rewards. Rewards will only get debased upon
claim! Rewards are currently set to 10,000,000 EGGS per block. Rewards can be changed by dev and is subject to change.

Depositing or claiming will incur 24 hours lock on withdrawals. Depositing or claiming will not extend the timer but the
timer will reset with another 24 hours. The debase is happening for the whole token supply including EGGS in vaults and
EGGS in LP. Since EGGS in LP also gets debased the amount of EGGS will decrease but the amount of ETH will remain the
same. That's the beauty of it since the price of EGGS will continue to increase if noone are selling and ETH is stable.

# Contracts

EGGS token has a mint function but the owner is a Timelock contract which has been set to 3 days. So everyone has time
to react for 3 days if dev does something.

[EGGS Token Contract](https://etherscan.io/token/0x2e516ba5bf3b7ee47fb99b09eadb60bde80a82e0)
[EggChef Farm Contract](https://etherscan.io/address/0xfc6a933a32aa6a382ea06d699a8b788a0bc49fcb)
[Full Protect Contract](https://etherscan.io/address/0x98d9f08824798d7fd37bd0dd740069baf31c37e7)

---
持有者手中的 Token 数量会自动削减，因此为了保证自己的持有量，参与者就必须在 Vault 中锁定自己的 Token。EGGS Token 的供应量以每个区块
0.001% 的速度减少，即约为每天 7%。为了避免持仓量的通缩，持有者需将 Token 放入三种 Vault：

1.Full Protec Vault，该方式锁定期为 7 天，用户可以存入 EGGS，7 天后取出，不会损耗任何 EGGS；

2.Big Protec Vault，该方式的锁定期为 24 小时，但需要存入 EGGS/ETH，ETH 不会受到影响，EGGS 仍然会受到每天 7% 的损耗，区别是用户会得到
90% 的奖励，即每个区块 1000 万 EGGS；

3.Smol Protec Vault，该方式的锁定期为 24 小时，也需要存入 EGGS，EGGS 仍会受到每天 7% 的损耗，用户会获得 Big Protec Vault
奖励（每个区块 1000 万 EGGS）标准的 10%。

