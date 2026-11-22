param(
  [Parameter(Mandatory)][string]$WorkRoot,
  [string]$PackageName = 'cef_binary_7871_windows_x64_v5',
  [string]$SevenZip = '7z',
  [string]$LibExe = 'lib.exe',
  [string]$Symchk = 'symchk.exe'
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if ($PackageName -notmatch '^cef_binary_7871_windows_x64_v[1-9][0-9]*$') { throw 'PackageName must match OBS naming: cef_binary_7871_windows_x64_vN.' }
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Run packaging with PowerShell 7 (pwsh).' }
if ($env:VisualStudioVersion -ne '18.0') { throw 'Run packaging from a Visual Studio 2026 x64 developer prompt.' }
$root = [IO.Path]::GetFullPath($WorkRoot)
$src = Join-Path $root 'download/chromium/src'
$out = Join-Path $src 'out/Release_GN_x64'
$cef = Join-Path $src 'cef'
$stageRoot = Join-Path $root 'staging'
$stage = Join-Path $stageRoot $PackageName
$symbols = Join-Path $stageRoot "${PackageName}_release_symbols"
$wrapperBuild = Join-Path $stageRoot "${PackageName}_wrapper_build"
$package = Join-Path (Join-Path $root 'package') $PackageName
$artifacts = Join-Path $root 'artifacts'
$zip = Join-Path $artifacts "$PackageName.zip"
$symbols7z = Join-Path $artifacts "${PackageName}_symbols.7z"
$inventory = Join-Path $artifacts "$PackageName.files.csv"
function Require-File([string]$path) { if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing: $path" } }
function Run([string]$file, [string[]]$arguments) {
  & $file @arguments
  if ($LASTEXITCODE -ne 0) { throw "$file failed with exit code $LASTEXITCODE" }
}
foreach ($path in @($stage, $symbols, $wrapperBuild, $package, $zip, $symbols7z, $inventory)) {
  if (Test-Path -LiteralPath $path) { throw "Output already exists: $path (use a new PackageName or move it aside)" }
}
Require-File (Join-Path $cef 'tools/make_distrib.py')
Require-File (Join-Path $out 'args.gn')
$expected = @{ cef='ed595aef8b4bf219b5e5fb1c9f600e756bef3019'; chromium='a6596a78725d07cf518fe958ac8fd18788530749'; depot='f4fadaf6a5ba1bced9d3d9021060667b563bf583' }
foreach ($entry in @(@($cef,$expected.cef),@($src,$expected.chromium),@((Join-Path $root 'depot_tools'),$expected.depot))) {
  $actual = (& git -C $entry[0] rev-parse HEAD).Trim()
  if ($LASTEXITCODE -ne 0 -or $actual -ne $entry[1]) { throw "Revision mismatch: $($entry[0])" }
}
$python = Join-Path $root 'depot_tools/python3.bat'
Require-File $python
$env:PATH = "$(Join-Path $root 'depot_tools');$env:PATH"
$env:DEPOT_TOOLS_WIN_TOOLCHAIN = '0'
$env:DEPOT_TOOLS_UPDATE = '0'
Run $python @((Join-Path $PSScriptRoot 'check-win-x64-args.py'), $src)
New-Item -ItemType Directory -Path $stageRoot,$artifacts,(Split-Path $package) -Force | Out-Null
Push-Location $cef
try { Run $python @('tools/make_distrib.py','--output-dir',$stageRoot,'--distrib-subdir',$PackageName,'--ninja-build','--x64-build','--allow-partial','--no-docs','--no-archive','--no-format') }
finally { Pop-Location }
if (-not (Test-Path -LiteralPath $stage -PathType Container)) { throw 'make_distrib did not create the distribution' }
if (-not (Test-Path -LiteralPath $symbols -PathType Container)) { throw 'make_distrib did not create Release symbols' }

Run cmake @('-S', (Join-Path $PSScriptRoot 'wrapper'), '-B', $wrapperBuild,
            '-G', 'Visual Studio 18 2026', '-A', 'x64', '-T', 'v145', "-DCEF_ROOT:PATH=$stage",
            '-DCEF_RUNTIME_LIBRARY_FLAG:STRING=/MT', '-DCEF_DEBUG_INFO_FLAG:STRING=/Zi')
Run cmake @('--build', $wrapperBuild, '--config', 'Release', '--target', 'check-wrapper')
$wrapperDir = Join-Path $package 'build/libcef_dll_wrapper/Release'
New-Item -ItemType Directory -Path $wrapperDir -Force | Out-Null
foreach ($name in @('libcef_dll_wrapper.lib', 'libcef_dll_wrapper.pdb')) {
  $file = Join-Path $wrapperBuild "libcef_dll_wrapper/Release/$name"
  Require-File $file
  Copy-Item -LiteralPath $file -Destination $wrapperDir
}
Run $LibExe @('/NOLOGO', '/LIST', (Join-Path $wrapperDir 'libcef_dll_wrapper.lib')) | Out-Null

& robocopy $stage $package /E /XD (Join-Path $stage 'build') /NFL /NDL /NJH /NJS /NP | Out-Null
if ($LASTEXITCODE -ge 8) { throw "robocopy failed with exit code $LASTEXITCODE" }
$tests = Join-Path $package 'tests'
if (Test-Path -LiteralPath $tests) { Rename-Item -LiteralPath $tests -NewName 'tests.disabled' }
$release = Join-Path $package 'Release'
foreach ($required in @('bootstrap.exe','bootstrapc.exe','chrome_elf.dll','libcef.dll','libcef.lib')) {
  Require-File (Join-Path $release $required)
}
foreach ($name in @('bootstrap.exe.pdb','bootstrapc.exe.pdb','chrome_elf.dll.pdb','dxcompiler.dll.pdb',
                    'libcef.dll.pdb','libEGL.dll.pdb','libGLESv2.dll.pdb','vk_swiftshader.dll.pdb','vulkan-1.dll.pdb')) {
  Require-File (Join-Path $symbols $name)
}
$pdbs = @(Get-ChildItem -LiteralPath $symbols -Filter '*.pdb' -File)
foreach ($pdb in $pdbs) {
  $binary = Join-Path $release ($pdb.Name -replace '\.pdb$','')
  Require-File $binary
  Copy-Item -LiteralPath $pdb.FullName -Destination (Join-Path $release $pdb.Name)
}
$symchkCommand = Get-Command $Symchk -ErrorAction SilentlyContinue
if (-not $symchkCommand) { throw 'symchk.exe is required to verify binary/PDB identity; pass -Symchk with its full path.' }
foreach ($pdb in $pdbs) { Run $symchkCommand.Source @('/q',(Join-Path $release ($pdb.Name -replace '\.pdb$','')),'/s',$release) }

$files = @(Get-ChildItem -LiteralPath $package -File -Recurse | Sort-Object FullName)
$rows = foreach ($file in $files) {
  [pscustomobject]@{ Path = $file.FullName.Substring($package.Length + 1).Replace('\','/'); Bytes = $file.Length; SHA256 = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash }
}
$rows | Export-Csv -LiteralPath $inventory -NoTypeInformation
Push-Location $package
try { Run $SevenZip @('a','-tzip','-mx=7',$zip,'.\*') }
finally { Pop-Location }
Push-Location $symbols
try { Run $SevenZip @('a','-t7z','-mx=7',$symbols7z,'.\*') }
finally { Pop-Location }
Run $SevenZip @('t',$zip)
Run $SevenZip @('t',$symbols7z)
$zipList = @(& $SevenZip l -slt $zip)
if ($LASTEXITCODE -ne 0) { throw 'Could not list runtime ZIP' }
$archivedFiles = @($zipList | Where-Object { $_ -eq 'Folder = -' }).Count
if ($archivedFiles -ne $rows.Count) { throw "ZIP has $archivedFiles files; inventory has $($rows.Count)" }
foreach ($artifact in @($zip,$symbols7z,$inventory)) {
  $item = Get-Item -LiteralPath $artifact
  Write-Host ("{0} {1} {2}" -f $item.Name,$item.Length,(Get-FileHash -LiteralPath $artifact -Algorithm SHA256).Hash)
}
