const fs = require('fs');

async function run() {

  const buffer = fs.readFileSync('./target/wasm32-unknown-unknown/release/rust_wasm_hello.wasm');
  const wasm = await WebAssembly.instantiate(buffer);

  const { add_one } = wasm.instance.exports;
  console.log(add_one(5));
}
run()
