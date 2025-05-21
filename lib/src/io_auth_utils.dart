// Copyright (c) 2017, alex. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

/// Support for doing something awesome.
///
/// More dartdocs go here.
library;

// TODO: Export any libraries intended for clients of this package.

import 'package:http/http.dart' as http;
import 'package:tekartik_io_auth_utils/src/io_auth_utils_file.dart';
import 'package:tekartik_io_auth_utils/src/io_auth_utils_memory.dart';
import 'package:tekartik_io_utils/io_utils_import.dart';

/// Load credentials from file system using default location (.local/client_id.yaml)
///
/// Content with the following form:
/// ```
/// # Get the data from google cloud console, new Client ID for Desktop application
/// client_id: 2**************************6.apps.googleusercontent.com
/// client_secret: v************g
/// ```
Future<http.Client> initAuthClient({
  required List<String> scopes,
  String? clientIdPath,
  Map? clientIdMap,
  String? credentialsPath,
  bool? verbose,
}) async {
  return initAuthClientWithParam(
    scopes: scopes,
    param: AuthCommonParamFile(
      clientIdPath: clientIdPath,
      clientIdMap: clientIdMap,
      credentialsPath: credentialsPath,
    ),
    verbose: verbose,
  );
}
