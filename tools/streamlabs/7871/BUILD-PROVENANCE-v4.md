# Streamlabs CEF 7871 Windows x64 v4

## Build

- Source pins: CEF `abc1ece6a66997894c4c953ed24937603fbd74b4`, Chromium `e7b998fb3cd79ff00dbc0067421dc6ec118892a8`, and depot_tools `f4fadaf6a5ba1bced9d3d9021060667b563bf583`.
- Visual Studio Community 2026 18.12.1, MSVC 14.52.37025, Windows SDK 10.0.26100.0, Windows x64 `Release_GN_x64`.
- `is_debug=false`, `is_official_build=false`, `symbol_level=1`, `proprietary_codecs=true`, `ffmpeg_branding="Chrome"`, Release DCHECKs disabled, and `enable_backup_ref_ptr_instance_tracer=false`.
- `build-win-x64.cmd` ran with `--reconfigure` against the pinned checkout. CEF's GN generator patch applied cleanly; the generated `args.gn` contains the settings above. `build-v4.log` ends with `Build Succeeded: 34625 steps` after 12h14m50s, linking `libcef.dll`, `bootstrap.exe`, `bootstrapc.exe`, and `cefclient.exe`.

## Artifacts

OBS constructs `cef_binary_VERSION_windows_ARCH_vREVISION.zip`; revision `4` yields the runtime name below. `package-win-x64.ps1` used the VS 2026 bundled CMake 4.3.1 and Windows Kits x64 `symchk.exe`.

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| `cef_binary_7871_windows_x64_v4.zip` | 907059636 | `ED982DECC5CDE723BB9D1D314108502E74DB7910F8AB0D247FE4DF53E835E28A` |
| `cef_binary_7871_windows_x64_v4_symbols.7z` | 407709760 | `BC75D94B474B9124B074B7B441D52D781DA4F282AC881794E9A137D12CEB0639` |
| `cef_binary_7871_windows_x64_v4.files.csv` | 164694 | `FD4F63662A1733C278A0314EB7D5432BFDC3664FF60928E3750853B8D94EFCA9` |

The packaging script built the `/MT` wrapper and linked its `std::vector` consumer check, validated nine runtime binary/PDB identities with `symchk`, and passed `7z t` for both archives. The runtime ZIP contains 1,389 files. Both uploaded S3 objects were streamed in full and their byte counts and SHA-256 hashes match the local artifacts.

- Runtime: `https://streamlabs-cef-dist.s3.us-west-2.amazonaws.com/cef_binary_7871_windows_x64_v4.zip`
- Symbols: `https://streamlabs-cef-dist.s3.us-west-2.amazonaws.com/cef_binary_7871_windows_x64_v4_symbols.7z`

OBS PR #804 selects revision `4` and the runtime hash above. Sandbox child-process startup and final signing still require validation in a normal packaged application.
