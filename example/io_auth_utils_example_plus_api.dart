// Copyright (c) 2017, alex. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:http/http.dart';
import 'package:tekartik_io_auth_utils/io_auth_utils.dart';
import 'package:tekartik_io_utils/io_utils_import.dart';
import 'package:path/path.dart';
import 'package:googleapis/plus/v1.dart';
import 'package:process_run/shell.dart';

String testFolderPath = "test";
String testDataFolderPath = join(testFolderPath, "data");

Future main() async {
  String appName = 'tekartik_io_auth_utils_example_plus_api';
  var dir =
      join(userAppDataPath, 'tekartik', 'io_auth_utils', 'example', appName);
  String path = join(dir, "client_id.json");
  if (File(path).existsSync()) {
    AuthClientInfo authClientInfo = await AuthClientInfo.load(filePath: path);
    print(authClientInfo);
    Client authClient =
        await authClientInfo.getClient([emailScope], localDirPath: dir);
    PlusApi plusApi = PlusApi(authClient);
    Person person = await plusApi.people.get("me");
    print(jsonPretty(person.toJson()));
  } else {
    await Directory(dir).create(recursive: true);
    stderr.write(
        "need secret file here: ${path} to download from <https://console.cloud.google.com/apis/credentials> section 'OAuth 2.0 client IDs");
  }
}
