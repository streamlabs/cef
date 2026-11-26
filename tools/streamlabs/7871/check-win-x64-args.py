import sys
from pathlib import Path


def main(src):
  sys.path.insert(0, str(src / 'cef' / 'tools'))
  from gn_args import ParseArgsFile

  path = src / 'out' / 'Release_GN_x64' / 'args.gn'
  args = ParseArgsFile(path)
  expected = {
      'target_cpu': 'x64',
      'is_debug': False,
      'is_official_build': False,
      'dcheck_always_on': False,
      'dcheck_is_configurable': False,
      'enable_backup_ref_ptr_instance_tracer': False,
      'proprietary_codecs': True,
      'ffmpeg_branding': 'Chrome',
      'symbol_level': 1,
  }
  for name, value in expected.items():
    actual = args.get(name)
    if type(actual) is not type(value) or actual != value:
      sys.exit(f'{path}: expected {name}={value!r}, got {actual!r}. '
               'Run build-win-x64.cmd with --reconfigure.')


if __name__ == '__main__':
  main(Path(sys.argv[1]).resolve())
