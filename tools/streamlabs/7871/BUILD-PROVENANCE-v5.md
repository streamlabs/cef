# Streamlabs CEF 7871 Windows x64 v5

## Build

- Source pins: OBS-based CEF `ed595aef8b4bf219b5e5fb1c9f600e756bef3019` (upstream CEF's `.289` update applied to `obsproject/cef:7871_obsproject`), Chromium `a6596a78725d07cf518fe958ac8fd18788530749` (`150.0.7871.289`), and depot_tools `f4fadaf6a5ba1bced9d3d9021060667b563bf583`.
- Visual Studio Community 2026 18.12.1, MSVC 14.52.37025, Windows SDK 10.0.26100.0, Windows x64 `Release_GN_x64`.
- `is_debug=false`, `is_official_build=false`, `symbol_level=1`, `proprietary_codecs=true`, `ffmpeg_branding="Chrome"`, Release DCHECKs disabled, and `enable_backup_ref_ptr_instance_tracer=false`.
- CEF applied all 120 Chromium patches. `build-v5-resume.log` ends with `Build Succeeded: 36436 steps` after 13h5m40s, linking `libcef.dll`, `bootstrap.exe`, `bootstrapc.exe`, and `cefclient.exe`.
- The pinned depot_tools checkout needed `allow-empty-gclient-condition.patch` for `.289` dependency sync. The managed build worker also needed local workarounds for Node esbuild process spawning, Python multiprocessing pipes, and AppContainer ACL stamping; these are not part of the packaged source or the fork's build patches.

## Artifacts

OBS constructs `cef_binary_VERSION_windows_ARCH_vREVISION.zip`; revision `5` yields the runtime name below. `package-win-x64.ps1` used the VS 2026 bundled CMake 4.3.1 and Windows Kits x64 `symchk.exe`.

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| `cef_binary_7871_windows_x64_v5.zip` | 907162486 | `84FCA3D4371266E20E5F3E7D1B3694F38247D25BA6ADC2F71C508649E761CF76` |
| `cef_binary_7871_windows_x64_v5_symbols.7z` | 407646751 | `B5999A3F1067F708E65895BEA6AA3713623BE483DBDEEA8F89F2660234A11D70` |
| `cef_binary_7871_windows_x64_v5.files.csv` | 164694 | `C2BE066C7BE5B6D84CB260A0C14AC9037EBAA000CCE0832C10F1068100AF9652` |

The packaging script built the `/MT` wrapper and linked its `std::vector` consumer check, validated nine runtime binary/PDB identities with `symchk`, and passed `7z t` for both archives. The runtime ZIP contains 1,389 files. The package header reports Chromium `150.0.7871.289`.

The artifacts are local. Hosted S3 byte and hash verification, OBS/OSN builds against v5, and packaged sandboxed startup and elevated Windows Graphics Capture checks remain to be completed.
