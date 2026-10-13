@TestOn('vm')
library;

import 'package:googleapis_auth/auth_io.dart';
import 'package:tekartik_io_auth_utils/io_auth_utils.dart';
import 'package:tekartik_io_auth_utils/src/io_auth_utils_memory.dart';
import 'package:tekartik_io_auth_utils/src/io_auth_utils_parse.dart';
import 'package:tekartik_io_utils/io_utils_import.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

/// Fake values only, no real client or token.
class _ParamMock implements AuthCommonParam {
  _ParamMock(this.credentialsMap);

  final Map? credentialsMap;
  var consentRequested = false;

  @override
  Future<Map> getClientIdMap() async => <String, Object?>{
    'client_id': 'mock_client_id',
    'client_secret': 'mock_client_secret',
  };

  @override
  Future<Map?> getCredentialsMap() async => credentialsMap;

  @override
  Future<void> promptUserConsent(String url) async {
    // Never called: no network in tests
    consentRequested = true;
  }

  @override
  Future<void> setCredentialsMap(Map map) => throw UnimplementedError();
}

Map<String, Object?> _savedCredentials({
  required Object? refreshToken,
  required DateTime expiry,
}) => {
  'token_type': 'Bearer',
  'token_data': 'mock_token_data',
  'token_expiry': '${expiry.toUtc()}',
  'refresh_token': refreshToken,
  'scopes': ['email'],
};

void main() {
  group('credentials', () {
    var future = DateTime.now().add(const Duration(hours: 1));
    var past = DateTime.now().subtract(const Duration(hours: 1));

    test('no refresh token saved', () async {
      for (var refreshToken in [null, 'null']) {
        var param = _ParamMock(
          _savedCredentials(refreshToken: refreshToken, expiry: future),
        );
        var info = await AuthClientInfoCommon.load(param: param);
        // It used to throw an ArgumentError (autoRefreshingClient)
        var client = await info.getClient(['email']);
        client.close();
        expect(param.consentRequested, isFalse);
      }
    });

    test('no refresh token saved and expired, log in again', () {
      // Not run through getClient: a new login starts the consent server.
      AccessCredentials saved({
        Object? refreshToken,
        required DateTime expiry,
      }) => accessCredentialsFromMap(
        _savedCredentials(refreshToken: refreshToken, expiry: expiry),
        ['email'],
      );
      expect(usableAccessCredentials(saved(expiry: past)), isNull);
      expect(usableAccessCredentials(saved(expiry: future)), isNotNull);
      expect(
        usableAccessCredentials(saved(refreshToken: 'mock', expiry: past)),
        isNotNull,
      );
    });

    test('refresh token kept', () async {
      var param = _ParamMock(
        _savedCredentials(refreshToken: 'mock_refresh', expiry: past),
      );
      var info = await AuthClientInfoCommon.load(param: param);
      var client = await info.getClient(['email']);
      client.close();
      expect(param.consentRequested, isFalse);
    });

    test('saved map round trip', () {
      for (var refreshToken in [null, 'mock_refresh']) {
        var credentials = accessCredentialsFromMap(
          _savedCredentials(refreshToken: refreshToken, expiry: future),
          ['email'],
        );
        var map = accessCredentialsToMap(credentials, ['email']);
        expect(map['refresh_token'], refreshToken);
        // As saved by AuthCommonParamFile and read back
        var readBack = loadYaml(jsonPretty(map)!) as Map;
        expect(
          accessCredentialsFromMap(readBack, ['email']).refreshToken,
          refreshToken,
        );
      }
    });
  });

  group('client id', () {
    test('parse', () {
      expect(parseClientIdMap({'client_id': 'id', 'client_secret': 's'}), (
        clientId: 'id',
        clientSecret: 's',
      ));
      expect(
        parseClientIdMap({
          'installed': {'client_id': 'id', 'client_secret': 's'},
        }),
        (clientId: 'id', clientSecret: 's'),
      );
      expect(parseClientIdMap({'other': 1}), (
        clientId: null,
        clientSecret: null,
      ));
    });

    test('toString redacts the secret', () async {
      var compat = (await AuthClientInfo.load(
        filePath: 'unused',
        map: {'client_id': 'mock_id', 'client_secret': 'mock_secret'},
      ))!;
      var common = await AuthClientInfoCommon.load(param: _ParamMock(null));
      for (var text in [compat.toString(), common.toString()]) {
        expect(text, isNot(contains('secret_')));
        expect(text, isNot(contains('mock_secret')));
        expect(text, isNot(contains('mock_client_secret')));
        expect(text, contains('<redacted>'));
      }
      expect(compat.toString(), contains('mock_id'));
    });
  });
}
