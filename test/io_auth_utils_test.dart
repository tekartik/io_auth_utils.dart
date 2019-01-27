import 'package:dev_test/test.dart';
import 'package:path/path.dart';
@TestOn("vm")
// Copyright (c) 2017, alex. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:tekartik_io_auth_utils/io_auth_utils.dart';
import 'package:tekartik_io_utils/io_utils_import.dart';

// Copyright (c) 2017, alex. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

String testFolderPath = "test";
String testDataFolderPath = join(testFolderPath, "data");

void main() {
  group('io_auth_utils', () {
    setUp(() {});

    test('no_file', () async {
      String path = join(testDataFolderPath, "never_exists.json");
      try {
        await AuthClientInfo.load(filePath: path);
        fail("missing");
      } on FileSystemException catch (_) {
        //devErr(e);
      }
      //print(authClientInfo.clientSecret);
    });

    test('bad_content', () async {
      String path = join(testDataFolderPath, "bad_content.json");
      AuthClientInfo authClientInfo = await AuthClientInfo.load(filePath: path);
      expect(authClientInfo, isNull);

      //print(authClientInfo.clientSecret);
    });

    test('not_json_content', () async {
      String path = join(testDataFolderPath, "basic_content.txt");
      AuthClientInfo authClientInfo = await AuthClientInfo.load(filePath: path);
      expect(authClientInfo, isNull);

      //print(authClientInfo.clientSecret);
    });

    test('tmp_only', () async {
      String path = join(testDataFolderPath,
          "tmp/client_secret_124267391961-qu3lag0eht68os2cfuj4khn4rb3i6k4g.apps.googleusercontent.com.json");
      if (File(path).existsSync()) {
        AuthClientInfo authClientInfo =
            await AuthClientInfo.load(filePath: path);
        print(authClientInfo.clientSecret);
      }
    });
  });
}
