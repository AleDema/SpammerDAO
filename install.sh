dfx start --background --clean --emulator 
# --host 127.0.0.1:8000


### === DEPLOY LOCAL LEDGER =====
# dfx identity new minter
# dfx identity use minter
# export MINT_ACC=$(dfx ledger account-id)

dfx identity use default
export LEDGER_ACC=$(dfx ledger account-id)

# Use private api for install
rm src/ledger/ledger.did
cp src/ledger/ledger.private.did src/ledger/ledger.did

dfx deploy ledger --argument '(record  {
    minting_account = "'${LEDGER_ACC}'";
    initial_values = vec { record { "'${LEDGER_ACC}'"; record { e8s=100_000_000_000 } }; };
    send_whitelist = vec {}
    })'
export LEDGER_ID=$(dfx canister id ledger)

# Replace with public api
rm src/ledger/ledger.did
cp src/ledger/ledger.public.did src/ledger/ledger.did

II_ENV=development dfx deploy internet_identity --no-wallet --argument '(null)'

## === INSTALL FRONTEND / BACKEND ==== 

dfx deploy backend 

# --argument "(opt principal \"$LEDGER_ID\")"

# rsync -avr .dfx/$(echo ${DFX_NETWORK:-'**'})/canisters/** --exclude='assets/' --exclude='idl/' --exclude='*.wasm' --delete src/frontend/declarations

# dfx canister create frontend
# pushd src/frontend
# npm install
# npm run build
# popd
# dfx build frontend
# dfx canister install frontend
npm i
npm start

# echo "===== VISIT DEFI FRONTEND ====="
# echo "http://localhost:8000?canisterId=$(dfx canister id frontend)"
# echo "===== VISIT DEFI FRONTEND ====="
