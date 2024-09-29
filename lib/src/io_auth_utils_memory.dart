// Copyright (c) 2017, alex. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

/// Support for doing something awesome.
///
/// More dartdocs go here.
library;

// TODO: Export any libraries intended for clients of this package.

import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:tekartik_io_utils/io_utils_import.dart';

String emailScope = 'email';
String userInfoProfileScope =
    'https://www.googleapis.com/auth/userinfo.profile';

String accessCredentialsFilename = 'access_credentials.yaml';

abstract class AuthCommonParam {
  Future<Map> getClientIdMap();
  Future<Map?> getCredentialsMap();
  Future<void> setCredentialsMap(Map map);
  Future<void> promptUserConsent(String url);
}

/// Load credentials from file system using default location (.local/client_id.yaml)
///
/// Content with the following form:
/// ```
/// # Get the data from google cloud console, new Client ID for Desktop application
/// client_id: 2**************************6.apps.googleusercontent.com
/// client_secret: v************g
/// ```
Future<http.Client> initAuthClientWithParam(
    {required List<String> scopes, required AuthCommonParam param}) async {
  final authClientInfo = (await AuthClientInfoCommon.load(param: param));
  print(authClientInfo);
  final authClient = await authClientInfo.getClient(scopes);
  return authClient;
}

/// Helper to load save credentials
class AuthClientInfoCommon {
  final AuthCommonParam param;
  final Map map;
  AuthClientInfoCommon({required this.param, required this.map}) {
    //final installedMap = map['installed'] as Map;
    // Handle this format:
    // # Get the data from google cloud console, new Client ID for Desktop application
    // client_id: 2**************************6.apps.googleusercontent.com
    // client_secret: v************g
    String? clientId;
    String? clientSecret;
    clientId = map['client_id'] as String?;
    if (clientId != null) {
      clientSecret = map['client_secret'] as String?;
    } else {
      // Handle this format:
      // {
      //   "installed": {
      //     "client_id": "83xxxxxom",
      //     "project_id": "soxxxxxo",
      //     "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      //     "token_uri": "https://oauth2.googleapis.com/token",
      //     "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
      //     "client_secret": "GOxxxxxIi",
      //     "redirect_uris": [
      //       "http://localhost"
      //     ]
      //   }
      // }
      var installedMap = map['installed'] as Map?;
      if (installedMap != null) {
        clientId = installedMap['client_id'] as String?;
        if (clientId != null) {
          clientSecret = installedMap['client_secret'] as String?;
        }
      }
    }
    this.clientId = clientId!;
    this.clientSecret = clientSecret!;
  }

  auth.ClientId get authClientId => auth.ClientId(clientId, clientSecret);
  auth.AccessCredentials? accessCredentials;

  late final String clientId;
  late final String clientSecret;

  String? credentialsPath;

  static Future<AuthClientInfoCommon> load(
      {required AuthCommonParam param}) async {
    var map = await param.getClientIdMap();
    return AuthClientInfoCommon(map: map, param: param);
  }

  @override
  String toString() {
    final map = {'clientId': clientId, 'clientSecret': clientSecret};
    return map.toString();
  }

  Future<http.Client> getClient(List<String> scopes) async {
    final identifier = authClientId;

    auth.AccessCredentials? accessCredentials;

    try {
      final yaml = await param.getCredentialsMap();
      if (yaml != null) {
        accessCredentials = auth.AccessCredentials(
            auth.AccessToken(
                yaml['token_type'] as String,
                yaml['token_data'] as String,
                DateTime.parse(yaml['token_expiry'] as String)),
            yaml['refresh_token'] as String?,
            scopes);
      }
      // AccessToken(type=Bearer, data=ya29.vgHGwmpTG_9AW5p5lHlL9PaJcnFmqSaKaa5ymS8vOD3_BxOkWF8IB1OLqFyMLbWonRbY, expiry=2015-07-28 17:08:31.241Z)
      // 1/Yc_wZlaDyKcMVXcYEE3-tzBVLBnLSsv_2ynfVzFO-59IgOrJDtdun6zK6XiATCKT
      //print(accessCredentials.accessToken);
      //print(accessCredentials.refreshToken);
    } catch (e, st) {
      stderr.writeln('error loading credentials, logging in');
      stderr.writeln(st);
      // exit(1);
    }

    var client = http.Client();

    if (accessCredentials == null) {
      accessCredentials = await auth.obtainAccessCredentialsViaUserConsent(
          identifier, scopes, client, param.promptUserConsent);
      print(accessCredentials.accessToken);
      print(accessCredentials.refreshToken);
      var map = {
        'token_type': accessCredentials.accessToken.type,
        'token_data': accessCredentials.accessToken.data,
        'token_expiry': '${accessCredentials.accessToken.expiry}',
        'refresh_token': '${accessCredentials.refreshToken}'
      };
      await param.setCredentialsMap(map);
    }

    final authClient =
        auth.autoRefreshingClient(identifier, accessCredentials, client);
    return authClient;
  }
}
