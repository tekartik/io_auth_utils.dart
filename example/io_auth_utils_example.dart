// Copyright (c) 2017, alex. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:googleapis/people/v1.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:tekartik_io_auth_utils/io_auth_utils.dart';
import 'package:tekartik_io_utils/io_utils_import.dart';

String testFolderPath = 'test';
String testDataFolderPath = join(testFolderPath, 'data');

Future main() async {
  final appName = 'tekartik_io_auth_utils_example';
  var dir =
      join(userAppDataPath, 'tekartik', 'io_auth_utils', 'example', appName);
  final path = join(dir, 'client_id.json');
  if (File(path).existsSync()) {
    final authClientInfo = await AuthClientInfo.load(filePath: path);
    print(authClientInfo);
    final authClient = await authClientInfo
        .getClient([userInfoProfileScope], localDirPath: dir);
    var peopleApi = PeopleApi(authClient);

    final person = await peopleApi.people.get('me');
    print(jsonPretty(person.toJson()));
  } else {
    await Directory(dir).create(recursive: true);
    stderr.write(
        "need secret file here: ${path} to download from <https://console.cloud.google.com/apis/credentials> section 'OAuth 2.0 client IDs");
  }
}
