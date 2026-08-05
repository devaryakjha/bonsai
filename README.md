# Bonsai

Bonsai is a native macOS Git client built with Rust and GPUI.

The app starts again from a small, visible flow. Each feature begins with a
spec and lands as a testable vertical slice.

## Run

Install the Rust toolchain and Xcode Metal Toolchain for macOS. Then run:

```sh
./script/build_and_run.sh
```

Use `./script/build_and_run.sh --verify` to build, launch, and verify the
foreground app process.
