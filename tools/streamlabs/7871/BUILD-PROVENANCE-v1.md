# Streamlabs CEF 7871 Windows x64 v1

## Source and configuration

- CEF: `abc1ece6a66997894c4c953ed24937603fbd74b4` (`7871_obsproject`), binary version `150.25.31-7871_obsproject.3563+gabc1ece+chromium-150.0.7871.287`.
- Chromium: `e7b998fb3cd79ff00dbc0067421dc6ec118892a8` (`150.0.7871.287`). Depot_tools: `f4fadaf6a5ba1bced9d3d9021060667b563bf583`.
- Windows x64 `Release_GN_x64` built with VS 2022 and `is_debug=false`, `is_official_build=false`, `symbol_level=1`, `proprietary_codecs=true`, `ffmpeg_branding="Chrome"`, `dcheck_always_on=false`, and `dcheck_is_configurable=false`. The generated `args.gn` is the source of truth.
- Chrome/win/x64 FFmpeg configuration enables H.264 and AAC decoders (`CONFIG_H264_DECODER=1`, `CONFIG_AAC_DECODER=1`).
- The managed worker denies Windows pipes used by Python multiprocessing. Local source changes select existing sequential modes in Mojo and Blink under `CEF_MANAGED_HOST=1`; a local esbuild fallback and AppContainer ACL stamp bypass also permit the build. These are build-host accommodations, not runtime sandbox modifications.

## Build and package

- `build-release-x64-resume4.log` ends with `Build Succeeded: 50181 steps`; `libcef.dll`, `bootstrap.exe`, `bootstrapc.exe`, and `cefclient.exe` linked successfully.
- CEF's `make_distrib.py` staged the standard Release distribution with headers, CMake/Bazel files, resources, runtime binaries, and separate Release symbols. `tests` was renamed to `tests.disabled` for the consumer layout.
- The wrapper archive uses the exact 213 `/MT` objects from GN's `obj/cef/libcef_dll_wrapper.ninja` target. `lib.exe` assembled a normal `!<arch>` archive at `build/libcef_dll_wrapper/Release/libcef_dll_wrapper.lib`; `lib /list` lists all 213 members. The GN archive itself is thin and unsuitable for an independent consumer.
- The nine Release PDBs were copied into `Release/` in the runtime ZIP and are also provided as a separate symbols archive. `symchk` passed for all nine binary/PDB pairs. `libcef.dll` matches its private PDB with RSDS GUID `{BF98D946-019F-8B60-4C4C-44205044422E}`, age 1.
- `libcef.dll`, `bootstrap.exe`, and `bootstrapc.exe` have x64 PE machine type `0x8664`.
- `7z t` passed on both archives. The runtime ZIP contains 1,388 files and 67 folders; its file count matches the SHA-256 CSV inventory. It contains `Release/bootstrap.exe`, `Release/bootstrapc.exe`, `Release/chrome_elf.dll`, `Release/libcef.dll`, `Release/libcef.dll.pdb`, and the normal wrapper archive.

## Deliverables

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| `artifacts/cef_binary_7871_windows_x64_v1.zip` | 893292991 | `A7D055B2EA24CEFB4963D5751D181343C1941A7095091EEAD8C5637405EFF153` |
| `artifacts/cef_binary_7871_windows_x64_v1_symbols.7z` | 436223000 | `AE783EAA7F7B712CCBDC4777A2A6665368E8C4205634A95EEBB8F5959736D63F` |
| `artifacts/cef_binary_7871_windows_x64_v1.files.csv` | 164557 | `B7F9C7571FFFFF6FA2FBDD2BFA4A701D060B7874C71C5A12643D52C9D93E6414` |

Key payload hashes are in the CSV inventory. `Release/libcef.dll` is `6B754D9A2F35FC22AD3630AFCCD24A1AA1E23F6B07FC8C62BF94CE2A0543A255` (315453952 bytes) and `Release/libcef.dll.pdb` is `D9D34D0CD44558CF0ECCBB2B1B1DAB14C8C1769D78E078C5963C46655B877063` (2606276608 bytes).

## Integration status

- The runtime and symbols archives are uploaded to `https://streamlabs-cef-dist.s3.us-west-2.amazonaws.com/`. The downloaded objects match the SHA-256 hashes above.
- CEF M138+ requires the Windows bootstrap launch model for a sandboxed external host. Draft PRs [obs-studio #804](https://github.com/streamlabs/obs-studio/pull/804), [obs-browser #61](https://github.com/streamlabs/obs-browser/pull/61), and [obs-studio-node #1855](https://github.com/streamlabs/obs-studio-node/pull/1855) contain the consumer changes. OBS merge PR #797 remains untouched.
- Installed layout, signing, and sandboxed browser/renderer/GPU subprocess behavior still need validation on a normal Windows host before the draft PRs are ready. The managed worker denies the named-pipe IPC used by CEF child processes; archive, PE, and symbol checks passed here.
