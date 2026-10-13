// Copyright (c) 2017, alex. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

/// Support for doing something awesome.
///
/// More dartdocs go here.
library;

// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:googleapis/oauth2/v2.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:tekartik_io_utils/io_utils_import.dart';

import 'io_auth_utils_parse.dart';

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
Future<http.Client> initAuthClientWithParam({
  required List<String> scopes,
  required AuthCommonParam param,
  bool? verbose,
}) async {
  final authClientInfo = (await AuthClientInfoCommon.load(param: param));
  // print(authClientInfo);
  final authClient = await authClientInfo.getClient(scopes);
  return authClient;
}

/// Helper to load save credentials
class AuthClientInfoCommon {
  final AuthCommonParam param;
  final Map map;
  AuthClientInfoCommon({required this.param, required this.map}) {
    var (:clientId, :clientSecret) = parseClientIdMap(map);
    this.clientId = clientId!;
    this.clientSecret = clientSecret!;
  }

  auth.ClientId get authClientId => auth.ClientId(clientId, clientSecret);
  auth.AccessCredentials? accessCredentials;

  late final String clientId;
  late final String clientSecret;

  String? credentialsPath;

  static Future<AuthClientInfoCommon> load({
    required AuthCommonParam param,
  }) async {
    var map = await param.getClientIdMap();
    return AuthClientInfoCommon(map: map, param: param);
  }

  @override
  String toString() => clientIdInfoToString(clientId, clientSecret);

  Future<http.Client> getClient(List<String> scopes) async {
    final identifier = authClientId;

    auth.AccessCredentials? accessCredentials;

    try {
      final yaml = await param.getCredentialsMap();
      if (yaml != null) {
        var existingScopes = (yaml['scopes'] as List?)?.toSet();
        var newScopes = scopes.toSet();
        if (const SetEquality<Object?>().equals(existingScopes, newScopes)) {
          accessCredentials = usableAccessCredentials(
            accessCredentialsFromMap(yaml, scopes),
          );
        } else {
          stderr.writeln('scopes do not match');
          stderr.writeln('existing: $existingScopes');
          stderr.writeln('new: $newScopes');
          stderr.writeln('Re-signing in');
        }
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

    if (accessCredentials != null && scopes.contains(userInfoProfileScope)) {
      final authClient = authClientFromCredentials(
        identifier,
        accessCredentials,
        client,
      );
      try {
        // Get me special!
        var oauth2Api = Oauth2Api(authClient);
        // Get me special!
        final userInfo = await oauth2Api.userinfo.get();
        // ignore: avoid_print
        print(jsonPretty(userInfo.toJson()));
        return authClient;
      } catch (e) {
        if (e is auth.ServerRequestFailedException) {
          // ignore: avoid_print
          print(e.message);
          var content = e.responseContent;

          if (content is Map && content['error'] == 'invalid_grant') {
            stderr.writeln(
              'error getting user info: $e ${e.runtimeType} - resigning in',
            );
            accessCredentials = null;
          }
        }

        if (accessCredentials != null) {
          stderr.writeln(
            'error getting user info: $e ${e.runtimeType} - trying anyway',
          );
        }
      }
    }
    if (accessCredentials == null) {
      accessCredentials = await auth.obtainAccessCredentialsViaUserConsent(
        identifier,
        scopes,
        client,
        param.promptUserConsent,
      );
      await param.setCredentialsMap(
        accessCredentialsToMap(accessCredentials, scopes),
      );
    }

    final authClient = authClientFromCredentials(
      identifier,
      accessCredentials,
      client,
    );

    return authClient;
  }
}
