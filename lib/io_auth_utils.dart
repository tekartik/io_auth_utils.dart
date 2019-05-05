// Copyright (c) 2017, alex. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

/// Support for doing something awesome.
///
/// More dartdocs go here.
library io_auth_utils;

// TODO: Export any libraries intended for clients of this package.

import 'dart:async';
import 'dart:io';

import 'package:fs_shim/utils/io/read_write.dart';
import 'package:googleapis_auth/auth.dart' as auth;
import 'package:googleapis_auth/auth_io.dart' as auth;
import "package:http/http.dart" as http;
import 'package:path/path.dart';
import 'package:tekartik_common_utils/json_utils.dart';
import 'package:yaml/yaml.dart';

String emailScope = "email";
String userInfoProfileScope =
    "https://www.googleapis.com/auth/userinfo.profile";

String _localPath = ".local";
//String credentialsFilename = 'client_id.yaml';
String accessCredentialsFilename = 'access_credentials.yaml';

class AuthClientInfo {
  AuthClientInfo(this.clientId, this.clientSecret);

  auth.ClientId get authClientId => auth.ClientId(clientId, clientSecret);
  auth.AccessCredentials accessCredentials;

  String clientId;
  String clientSecret;

  String credentialsPath;

  static Future<AuthClientInfo> load({String filePath, Map map}) async {
    if (map == null) {
      map = parseJsonObject(await File(filePath).readAsString());
    }
    if (map != null) {
      Map installedMap = map['installed'] as Map;
      String clientId = installedMap['client_id'] as String;
      String clientSecret = installedMap['client_secret'] as String;
      if (clientId != null && clientSecret != null) {
        return AuthClientInfo(clientId, clientSecret);
      } else {
        stderr.writeln("invalid map: ${map}");
        //return new AuthClientInfo(map, clientSecret)
      }
    }
    return null;
  }

  @override
  String toString() {
    Map map = {"clientId": clientId, "clientSecret": clientSecret};
    return map.toString();
  }

  Future<http.Client> getClient(List<String> scopes,
      {String localDirPath, String packageName}) async {
    auth.ClientId identifier = authClientId;

    /*
      Map yaml = loadYaml(
          new File(join(localDirPath, credentialsFilename)).readAsStringSync());
      String clientId = yaml['id'];
      String clientSecret = yaml['secret'];
      //print(clientId);
      //print(clientSecret);

      identifier = new auth.ClientId(clientId, clientSecret);
    } catch (e, st) {
      stderr.writeln(
          'client id file not found, $credentialsFilename with the following content');
      stderr.writeln(
          "id: xxxxxxxx-qu3lag0eht68os2cfuj4khn4rb3i6k4g.apps.googleusercontent.com");
      stderr.writeln("secret: yyyy-8l_c2yeDRFm_vdnEEvs");
      stderr.writeln(st);
      throw e;
    }
    */

    if (packageName != null) {
      if (localDirPath == null) {
        localDirPath = join(_localPath, packageName);
      } else {
        localDirPath = join(localDirPath, _localPath, packageName);
      }
    }

    localDirPath ??= _localPath;

    String credentialsPath = join(localDirPath, accessCredentialsFilename);

    auth.AccessCredentials accessCredentials;
    try {
      Map yaml = loadYaml(File(credentialsPath).readAsStringSync()) as Map;
      accessCredentials = auth.AccessCredentials(
          auth.AccessToken(
              yaml['token_type'] as String,
              yaml['token_data'] as String,
              DateTime.parse(yaml['token_expiry'] as String)),
          yaml['refresh_token'] as String,
          scopes);
      // AccessToken(type=Bearer, data=ya29.vgHGwmpTG_9AW5p5lHlL9PaJcnFmqSaKaa5ymS8vOD3_BxOkWF8IB1OLqFyMLbWonRbY, expiry=2015-07-28 17:08:31.241Z)
      // 1/Yc_wZlaDyKcMVXcYEE3-tzBVLBnLSsv_2ynfVzFO-59IgOrJDtdun6zK6XiATCKT
      //print(accessCredentials.accessToken);
      //print(accessCredentials.refreshToken);
    } catch (e, st) {
      stderr.writeln('Credential file not found');
      stderr.writeln(st);
      // exit(1);
    }

    var client = http.Client();

    if (accessCredentials == null) {
      accessCredentials = await auth.obtainAccessCredentialsViaUserConsent(
          identifier, scopes, client, _userPrompt);
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

    //accessCredentials == await auth.obtainAccessCredentialsViaUserConsent(identifier, scopes, client, _userPrompt);
    /*.catchError((error) {
      if (error is auth.UserConsentException) {
        print("You did not grant access :(");
      } else {
        print("An unknown error occured: $error");
      }
      client.close();
      throw error;
    });
    */

    auth.AutoRefreshingAuthClient authClient =
        auth.autoRefreshingClient(identifier, accessCredentials, client);
    return authClient;
  }
}

/*
Future deleteAccessCredentials(String localDirPath) async {
  await (new File(join(localDirPath, accessCredentialsFilename)).delete());
}
*/

void _userPrompt(String url) {
  print("Please go to the following URL and grant access:");
  print("  => $url");
  print("");
}
