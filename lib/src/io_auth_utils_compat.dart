// Copyright (c) 2017, alex. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

/// Support for doing something awesome.
///
/// More dartdocs go here.
library io_auth_utils;

// TODO: Export any libraries intended for clients of this package.

import 'package:fs_shim/utils/io/read_write.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:tekartik_io_auth_utils/src/io_auth_utils_file.dart';
import 'package:tekartik_io_utils/io_utils_import.dart';
import 'package:yaml/yaml.dart';

String emailScope = 'email';
String userInfoProfileScope =
    'https://www.googleapis.com/auth/userinfo.profile';

String _localPath = '.local';
//String credentialsFilename = 'client_id.yaml';
String accessCredentialsFilename = 'access_credentials.yaml';

/// Helper to load save credentials
class AuthClientInfo {
  AuthClientInfo(this.clientId, this.clientSecret);

  auth.ClientId get authClientId => auth.ClientId(clientId, clientSecret);
  auth.AccessCredentials? accessCredentials;

  String clientId;
  String clientSecret;

  String? credentialsPath;

  static Future<AuthClientInfo?> load(
      {required String filePath, Map? map}) async {
    map ??= loadYaml(await File(filePath).readAsString()) as Map?;
    if (map != null) {
      //final installedMap = map['installed'] as Map;
      // Handle this format:
      // # Get the data from google cloud console, new Client ID for Desktop application
      // client_id: 2**************************6.apps.googleusercontent.com
      // client_secret: v************g
      var clientId = map['client_id'] as String?;
      String? clientSecret;
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
      if (clientSecret != null) {
        return AuthClientInfo(clientId!, clientSecret);
      }
      stderr.writeln('invalid map: $map');
    }
    return null;
  }

  @override
  String toString() {
    final map = {'clientId': clientId, 'clientSecret': clientSecret};
    return map.toString();
  }

  Future<http.Client> getClient(List<String> scopes,
      {String? localDirPath,
      String? packageName,
      String? credentialsPath}) async {
    final identifier = authClientId;

    if (credentialsPath == null) {
      if (packageName != null) {
        if (localDirPath == null) {
          localDirPath = join(_localPath, packageName);
        } else {
          localDirPath = join(localDirPath, _localPath, packageName);
        }
      }

      localDirPath ??= _localPath;

      credentialsPath = join(localDirPath, accessCredentialsFilename);
    }

    auth.AccessCredentials? accessCredentials;

    var file = File(credentialsPath);
    if (!file.existsSync()) {
      stderr.writeln('Credential file not found, logging in');
    } else {
      try {
        final yaml = loadYaml(File(credentialsPath).readAsStringSync()) as Map;
        accessCredentials = auth.AccessCredentials(
            auth.AccessToken(
                yaml['token_type'] as String,
                yaml['token_data'] as String,
                DateTime.parse(yaml['token_expiry'] as String)),
            yaml['refresh_token'] as String?,
            scopes);
        // AccessToken(type=Bearer, data=ya29.vgHGwmpTG_9AW5p5lHlL9PaJcnFmqSaKaa5ymS8vOD3_BxOkWF8IB1OLqFyMLbWonRbY, expiry=2015-07-28 17:08:31.241Z)
        // 1/Yc_wZlaDyKcMVXcYEE3-tzBVLBnLSsv_2ynfVzFO-59IgOrJDtdun6zK6XiATCKT
        //print(accessCredentials.accessToken);
        //print(accessCredentials.refreshToken);
      } catch (e, st) {
        stderr.writeln('error loading credentials, logging in');
        stderr.writeln(st);
        // exit(1);
      }
    }

    var client = http.Client();

    if (accessCredentials == null) {
      accessCredentials = await auth.obtainAccessCredentialsViaUserConsent(
          identifier, scopes, client, ioPromptUser);
      print(accessCredentials.accessToken);
      print(accessCredentials.refreshToken);
      //new File(join(localDirPath, accessCredentialsFilename))
//            .writeAsStringSync('''
      await writeString(File(join(credentialsPath)), '''
token_type: ${accessCredentials.accessToken.type}
token_data: ${accessCredentials.accessToken.data}
token_expiry: ${accessCredentials.accessToken.expiry}
refresh_token: ${accessCredentials.refreshToken}
''');
    }

    final authClient =
        auth.autoRefreshingClient(identifier, accessCredentials, client);
    return authClient;
  }
}
