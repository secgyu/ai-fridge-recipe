// 모든 SVG 자산을 `.svg.vec`로 일괄 사전 컴파일.
//
// 실행:
//   dart run tool/compile_svgs.dart
//
// 새 SVG 자산 폴더를 추가했다면 아래 [_svgDirs]에 경로를 추가하세요.
// 산출물(`*.svg.vec`)은 git에 커밋합니다. 컴파일러 버전을 고정해 빌드 결정성을 보장.
import 'dart:io';

const List<String> _svgDirs = <String>[
  'assets/images/auth',
  // TODO(svg): 신규 SVG 자산 폴더 등록 위치
];

Future<void> main() async {
  for (final String dir in _svgDirs) {
    stdout.writeln('Compiling SVGs in $dir ...');
    final ProcessResult result = await Process.run('dart', <String>[
      'run',
      'vector_graphics_compiler',
      '--input-dir',
      dir,
      '--tessellate',
    ], runInShell: true);
    stdout.write(result.stdout);
    if (result.exitCode != 0) {
      stderr.write(result.stderr);
      exit(result.exitCode);
    }
  }
  stdout.writeln('Done.');
}
