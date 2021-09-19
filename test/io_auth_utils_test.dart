@TestOn('vm')
import 'package:dev_test/test.dart';
import 'package:path/path.dart';
import 'package:tekartik_io_auth_utils/io_auth_utils.dart';
import 'package:tekartik_io_utils/io_utils_import.dart';

// Copyright (c) 2017, alex. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

String testFolderPath = 'test';
String testDataFolderPath = join(testFolderPath, 'data');

void main() {
  group('io_auth_utils', () {
    setUp(() {});

    test('no_file', () async {
      final path = join(testDataFolderPath, 'never_exists.json');
      try {
        await AuthClientInfo.load(filePath: path);
        fail('missing');
      } on FileSystemException catch (_) {
        //devErr(e);
      }
      //print(authClientInfo.clientSecret);
    });

    test('google_content', () async {
      final path = join('.local', 'client_id.example.yaml');
      var client = (await AuthClientInfo.load(filePath: path))!;
      expect(client.clientId, contains('*****'));
      expect(client.clientSecret, contains('*****'));
    });

    test('bad_content', () async {
      final path = join(testDataFolderPath, 'bad_content.json');
      try {
        await AuthClientInfo.load(filePath: path);
        fail('should fail');
      } catch (e) {
        expect(e, isNot(const TypeMatcher<TestFailure>()));
      }

      //print(authClientInfo.clientSecret);
    });

    test('not_json_content', () async {
      final path = join(testDataFolderPath, 'basic_content.txt');
      try {
        await AuthClientInfo.load(filePath: path);
        fail('should fail');
      } catch (e) {
        expect(e, isNot(const TypeMatcher<TestFailure>()));
      }

      //print(authClientInfo.clientSecret);
    });

    test('tmp_only', () async {
      final path = join(testDataFolderPath,
          'tmp/client_secret_124267391961-qu3lag0eht68os2cfuj4khn4rb3i6k4g.apps.googleusercontent.com.json');
      if (File(path).existsSync()) {
        final authClientInfo = await (AuthClientInfo.load(filePath: path)
            as FutureOr<AuthClientInfo>);
        print(authClientInfo.clientSecret);
      }
    });
  });
}
