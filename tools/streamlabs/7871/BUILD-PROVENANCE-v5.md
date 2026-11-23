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

## Local consumer validation

- OBS PR #804's checkout selected revision 5 and the local ZIP hash above. A full Windows x64 `RelWithDebInfo` build passed with VS 2026; `obs-browser.dll` and `obs-browser-child.dll` linked. Runtime and Development installed into `obs-studio-node/build/libobs-src`. The installed `libcef.dll`, `chrome_elf.dll`, and `bootstrapc.exe` match the v5 package by SHA-256.
- OBS native CTest passed 181/183. The two failures match the v4 managed-worker path checks: temporary drive mapping and a missing UNC share returning access denied instead of file not found.
- OSN PR #1855's checkout built and installed against the v5 OBS SDK. The installed `obs64.exe` matches v5 `bootstrapc.exe`; its `chrome_elf.dll` and `libcef.dll` match the package. Focused CEF and token-policy tests passed 9/9. The full OSN native suite passed 233/234; the same v4 fixture test fails because `config_save_safe` returns `-2` when saving its config.
- OBS's broad build needed a generated OpenVR update script to skip an unnecessary Git submodule command on this worker. The change is local to the build tree and is not in the OBS PR.

The artifacts are local. Hosted S3 byte and hash verification, OBS PR #804's revision 5 update, and packaged sandboxed startup and elevated Windows Graphics Capture checks remain to be completed.
