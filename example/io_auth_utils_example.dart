// Copyright (c) 2017, alex. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:googleapis/people/v1.dart';
import 'package:path/path.dart';
import 'package:tekartik_io_auth_utils/io_auth_utils.dart';
import 'package:tekartik_io_utils/io_utils_import.dart';

String testFolderPath = 'test';
String testDataFolderPath = join(testFolderPath, 'data');

Future main() async {
  var authClient = await initAuthClient(
      scopes: [userInfoProfileScope, PeopleApi.ContactsScope]);
  var peopleApi = PeopleApi(authClient);

  // Get me special!
  final person = await peopleApi.people.get('people/me', personFields: 'names');
  print(jsonPretty(person.toJson()));
}
