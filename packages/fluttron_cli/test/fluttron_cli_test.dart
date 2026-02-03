import 'package:test/test.dart';

import 'package:fluttron_cli/fluttron_cli.dart';

void main() {
  test('help exits with success', () async {
    final exitCode = await runCli(['--help']);
    expect(exitCode, 0);
  });
}
