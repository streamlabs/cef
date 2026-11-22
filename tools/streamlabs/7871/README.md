# CEF 7871 Windows x64 build

Builds the OBS Project CEF 7871 branch with VS 2026 and packages a Release runtime with matching PDBs and a self-contained `/MT` wrapper. The source includes upstream CEF's Chromium 150.0.7871.289 update on top of OBS's `7871_obsproject` branch. Earlier packages are recorded in [v1 provenance](BUILD-PROVENANCE-v1.md), [v2 provenance](BUILD-PROVENANCE-v2.md), and [v4 provenance](BUILD-PROVENANCE-v4.md). A new build gets new hashes; do not reuse a recorded artifact hash.

| Repository | Revision |
| --- | --- |
| `https://github.com/streamlabs/cef.git` (OBS `7871_obsproject` plus upstream `.289` update) | `ed595aef8b4bf219b5e5fb1c9f600e756bef3019` |
| Chromium `150.0.7871.289` | `a6596a78725d07cf518fe958ac8fd18788530749` |
| depot_tools | `f4fadaf6a5ba1bced9d3d9021060667b563bf583` |

Use Windows x64, VS 2026 C++ tools, a suitable Windows SDK with `symchk.exe`, Git with long paths enabled, Python/depot_tools prerequisites, 7-Zip, and ample disk space. Install depot_tools at `<work>\depot_tools` and checkout its pin; clone CEF at `<work>\cef` and checkout its pin. The script syncs Chromium from the GitHub mirror and checks all three resulting HEADs. Set `VSDEVCMD` if VS is installed in a different edition/location, `CEF_JOBS` to cap parallel compilation, and `GIT_USR_BIN` if Git's Unix tools are not on `PATH`. The build and packaging scripts never change an existing pin themselves.

The build script applies `allow-empty-gclient-condition.patch` to the pinned depot_tools checkout before syncing `.289`. It handles an empty variable in the Chromium dependency conditions; without it, `gclient sync` fails with `SyntaxError: invalid syntax`. The patch is idempotent and leaves the depot_tools commit pin unchanged.

```cmd
set VSDEVCMD=C:\path\to\VS2026\Common7\Tools\VsDevCmd.bat
set CEF_JOBS=8
build-win-x64.cmd D:\cef-work
```

To upgrade an existing checkout after syncing the new CEF and Chromium pins, run `build-win-x64.cmd D:\cef-work --reconfigure`. For a fresh checkout, omit `--reconfigure` and let the script sync the pinned sources. The script applies the included GN generator patch, regenerates `out/Release_GN_x64/args.gn`, and rebuilds `cefclient bootstrap bootstrapc`. CEF 7871 normally forces pointer-instance tracing on for this Windows configuration. We set `enable_backup_ref_ptr_instance_tracer=false` because the tracer can deadlock during browser startup.

To continue an interrupted v5 build, run `build-win-x64.cmd D:\cef-work --resume`. Both build modes and the packager check the generated args, including `proprietary_codecs=true` and `ffmpeg_branding="Chrome"` for H.264/AAC and `symbol_level=1` for crash symbols.

After the v5 build completes, package it from a VS 2026 x64 developer command prompt with PowerShell 7 and CMake 4.2 or later. The default package name is `cef_binary_7871_windows_x64_v5`. Use Windows x64 revision `5` when pinning this package in OBS.

```powershell
pwsh -NoProfile -File .\package-win-x64.ps1 -WorkRoot D:\cef-work
```

After `make_distrib.py`, the packaging script builds the distribution's `libcef_dll_wrapper` CMake target with MSVC, the Microsoft C++ standard library, `/MT`, and `/Zi`. It links a consumer that passes a `std::vector` across the wrapper API, exercising the same library boundary as obs-browser. The runtime ZIP includes both `libcef_dll_wrapper.lib` and its compiler PDB in `build/libcef_dll_wrapper/Release/`. The nine runtime PDBs are checked against their binaries with `symchk.exe` and included in the symbols 7z and the runtime ZIP's `Release/` directory.

The runtime ZIP, symbols 7z, and SHA-256 CSV inventory are written to `<work>\artifacts`. Pass `-Symchk` with a full path if the SDK tool is not on `PATH`. Use a fresh package name for each build.

The original local build needed host-specific accommodations for denied Python multiprocessing pipes, esbuild execution, AppContainer ACL stamping, and depot_tools vpython storage. They are deliberately not carried as patches: the esbuild and ACL changes were local workarounds without a portable safety proof. On a similarly restricted host, resolve and review those issues separately before building. A sandboxed CEF child-process smoke test also needs a normal Windows host and the M138+ bootstrap integration in the consuming application; archive checks alone do not establish runtime sandbox support.
