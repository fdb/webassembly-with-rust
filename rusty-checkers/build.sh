cargo build --release --target wasm32-unknown-unknown && \
wasm-gc target/wasm32-unknown-unknown/release/rusty_checkers.wasm
