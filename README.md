# Panorama Viewer

Building:

```bash
RUSTFLAGS=--cfg=web_sys_unstable_apis wasm-pack build --target web
```

NOTE: `RUSTFLAGS` is only required when compiling with the WebGPU backend.
