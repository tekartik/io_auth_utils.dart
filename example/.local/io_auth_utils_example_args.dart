// Copyright (c) 2017, alex. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart';
import 'package:tekartik_io_utils/io_utils_import.dart';

import '../io_auth_utils_example.dart';

Future main() async {
  await runExample(
      clientIdPath: join('.local', 'client_id.yaml'),
      credentialsPath: join('.local', 'access_credentials_args.yaml'));
}
