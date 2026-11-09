// Copyright (c) 2017, alex. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

/// [initAuthClient] implementation.
library;

import 'package:http/http.dart' as http;
import 'package:tekartik_io_auth_utils/src/io_auth_utils_file.dart';
import 'package:tekartik_io_auth_utils/src/io_auth_utils_memory.dart';
import 'package:tekartik_io_utils/io_utils_import.dart';

/// An authenticated client for [scopes], asking the user consent on the
/// console when there is no usable cached token.
///
/// The client id is [clientIdMap], else the file [clientIdPath] (default
/// `.local/client_id.yaml`), of this form (or the JSON downloaded from the
/// Google Cloud console):
/// ```
/// # Get the data from google cloud console, new Client ID for Desktop application
/// client_id: 2**************************6.apps.googleusercontent.com
/// client_secret: v************g
/// ```
///
/// The tokens are cached in [credentialsPath] (default
/// `.local/access_credentials.yaml`) with their scopes: another scope set
/// starts a new consent. [verbose] is not used.
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
