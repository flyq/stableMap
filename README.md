# stableMap
```sh
sudo dfx canister --no-wallet install stableMap --argument='("logo", "name", "symbol", 8, 1_000_000_000, principal "yhy6j-huy54-mkzda-m26hc-yklb3-dzz4l-i2ykq-kr7tx-dhxyf-v2c2g-tae", true, true)'

dfx canister --no-wallet call stableMap balanceOf '(principal "yhy6j-huy54-mkzda-m26hc-yklb3-dzz4l-i2ykq-kr7tx-dhxyf-v2c2g-tae")'
(1_000_000_000 : nat)


dfx canister --no-wallet call stableMap balanceOf '(principal "ktfx3-4dj7o-f4lqf-gab56-fgkuw-aagt6-jzpkd-o7xzp-f6a3p-nm6wl-wae")'
(0 : nat)

dfx canister --no-wallet call stableMap transfer '(principal "ktfx3-4dj7o-f4lqf-gab56-fgkuw-aagt6-jzpkd-o7xzp-f6a3p-nm6wl-wae", 100_000)'
(true)

dfx canister --no-wallet call stableMap balanceOf '(principal "yhy6j-huy54-mkzda-m26hc-yklb3-dzz4l-i2ykq-kr7tx-dhxyf-v2c2g-tae")'
(999_900_000 : nat)

dfx canister --no-wallet call stableMap balanceOf '(principal "ktfx3-4dj7o-f4lqf-gab56-fgkuw-aagt6-jzpkd-o7xzp-f6a3p-nm6wl-wae")'
(100_000 : nat)

sudo dfx canister --no-wallet install stableMap --argument='("logo", "name", "symbol", 8, 1_000_000_000, principal "yhy6j-huy54-mkzda-m26hc-yklb3-dzz4l-i2ykq-kr7tx-dhxyf-v2c2g-tae", true, true)' -m=upgrade
Upgrading code for canister stableMap, with canister_id rwlgt-iiaaa-aaaaa-aaaaa-cai

dfx canister --no-wallet call stableMap balanceOf '(principal "yhy6j-huy54-mkzda-m26hc-yklb3-dzz4l-i2ykq-kr7tx-dhxyf-v2c2g-tae")'
(1_000_000_000 : nat)

dfx canister --no-wallet call stableMap balanceOf '(principal "ktfx3-4dj7o-f4lqf-gab56-fgkuw-aagt6-jzpkd-o7xzp-f6a3p-nm6wl-wae")'
(100_000 : nat)