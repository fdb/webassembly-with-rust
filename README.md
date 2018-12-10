# WebAssembly with Rust

Explorations in WebAssembly with Rust, based on the book [Programming WebAssembly with Rust](https://pragprog.com/book/khrust/programming-webassembly-with-rust) by Kevin Hoffman.

# Checkers in pure WebAssembly

The directory `checkers` contains a version of Checkers in pure WebAssembly, using the `.wat` format. It corresponds to chapter 2 of the book.

The code is in `checkers/checkers.wat`.

## GUI

![Checkers screenshot](https://raw.github.com/fdb/webassembly-with-rust/master/.github/checkers-screenshot.png)

I've added a graphical user interface so you're able to play the game! The interface uses [Preact](https://preactjs.com/) and [htm](https://github.com/developit/htm). All code taken together takes up less than 8KB gzipped.

Right now you can't drag the pieces. You can click them, then click where they need to go. In the right corner you can see who's turn it is.

## Testing

We test the WebAssembly module by loading it into Node.js, then using [Mocha](https://mochajs.org/) to describe the behavior of the module. Tests are in `test.js`.

To run the tests you need Node.js and the [Web Assembly Binary Toolkit](https://github.com/WebAssembly/wabt) (wabt). On macOS you can install those using Homebrew:

```
brew install node wabt
```

Then, to build and test the module run `npm test`.

# Checkers in Rust

The `rusty-checkers` folder contains the (unfinished) Rust version of Checkers. To install Rust on macOS you can run the following:

```
curl https://sh.rustup.rs -sSf | sh
```
