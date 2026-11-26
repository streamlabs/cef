# Streamlabs CEF 7871 Windows x64 v2

## Build

- Source pins match [v1](BUILD-PROVENANCE-v1.md): CEF `abc1ece6a66997894c4c953ed24937603fbd74b4`, Chromium `e7b998fb3cd79ff00dbc0067421dc6ec118892a8`, and depot_tools `f4fadaf6a5ba1bced9d3d9021060667b563bf583`.
- Visual Studio Community 2026 18.12.1, MSVC 14.52.37025, Windows SDK 10.0.26100.0. The regenerated `toolchain.ninja` and `environment.x64` point to the VS 2026 headers and libraries.
- Windows x64 `Release_GN_x64`, `is_debug=false`, `is_official_build=false`, `symbol_level=1`, `proprietary_codecs=true`, `ffmpeg_branding="Chrome"`, and Release DCHECKs disabled. `build-vs2026.log` ends with `Build Succeeded: 52035 steps` after 14h37m; `libcef.dll`, `bootstrap.exe`, `bootstrapc.exe`, and `cefclient.exe` linked.
- The same managed-worker source accommodations described in v1 permitted compilation. They are not runtime sandbox changes. An installed sandboxed child-process test remains required on a normal Windows host.

## Artifacts

OBS Windows buildspec constructs `cef_binary_VERSION_windows_ARCH_vREVISION.zip`. With version `7871`, architecture `x64`, and revision `2`, the exact expected runtime name is `cef_binary_7871_windows_x64_v2.zip`. The symbols and inventory use the same stem. The packaging run used a temporary `vs2026_v2r1` output name after an incomplete attempt, then the three completed files were renamed without changing their bytes.

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| `cef_binary_7871_windows_x64_v2.zip` | 882632362 | `E3C9067C7E9CEF70CD8299D391684EDD5FB7CCE8DC5151EC2E9A2E6D7F40B1D4` |
| `cef_binary_7871_windows_x64_v2_symbols.7z` | 412077394 | `9A5DFF6559A2E9075EF6CB6450A347CAD6D299D46793D72AD5A60C9E10282D07` |
| `cef_binary_7871_windows_x64_v2.files.csv` | 164557 | `851483E5857C7AECC8393F7B969286102B7690DAC87EAB3DC8915E6B05DB9192` |

The runtime ZIP contains 1,388 files, including `Release/libcef.dll`, its matching PDB, `bootstrap.exe`, `bootstrapc.exe`, `chrome_elf.dll`, and a normal `/MT` wrapper archive with 213 objects. The package script passed `symchk` on all nine binary/PDB pairs and `7z t` on both archives. `Release/libcef.dll` is 315506176 bytes with SHA-256 `E44D7DEA558E779DC92039EC972109E4403C7B6C4491ADD0C4470879402040DA`; its private PDB is 2606383104 bytes with SHA-256 `6D3F71665EBC7D221BC6E4F70BC09B5DE91C01D05B7D8E087932081AE5334A81`.

## Integration

- The runtime ZIP is hosted at `https://streamlabs-cef-dist.s3.us-west-2.amazonaws.com/cef_binary_7871_windows_x64_v2.zip`; the symbols archive is hosted at `https://streamlabs-cef-dist.s3.us-west-2.amazonaws.com/cef_binary_7871_windows_x64_v2_symbols.7z`. Both uploaded objects were streamed in full and their SHA-256 hashes match the local files above. Draft OBS PR #804 selects Windows x64 revision `2` and its runtime hash. PR #797 remains untouched.
- The VS 2026 package has not completed an installed browser/renderer/GPU sandbox smoke test or signing validation. Keep the consumer PRs in draft until those checks pass.
