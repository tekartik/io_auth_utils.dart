// Copyright (c) 2017, alex. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:http/http.dart';
import 'package:tekartik_io_auth_utils/io_auth_utils.dart';
import 'package:tekartik_io_utils/io_utils_import.dart';
import 'package:path/path.dart';
import 'package:googleapis/plus/v1.dart';

String testFolderPath = "test";
String testDataFolderPath = join(testFolderPath, "data");


main() async {
  String path = join(testDataFolderPath,
      "tmp", "client_secret_124267391961-qu3lag0eht68os2cfuj4khn4rb3i6k4g.apps.googleusercontent.com.json");
  if (await new File(path).exists()) {
    AuthClientInfo authClientInfo = await AuthClientInfo.load(
        filePath: path);
    print(authClientInfo);
    Client authClient = await authClientInfo.getClient([emailScope]);
    PlusApi plusApi = new PlusApi(authClient);
    Person person = await plusApi.people.get("me");
    print(person.toJson());

    authClient = await authClientInfo.getClient([emailScope], packageName: "com.tekartik.io_auth_utils.dart");
    plusApi = new PlusApi(authClient);
    person = await plusApi.people.get("me");
    print(person.toJson());
  } else {
    stderr.write("need secret file here: ${path}");
  }
}
