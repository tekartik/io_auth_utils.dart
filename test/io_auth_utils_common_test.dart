import 'package:dev_test/test.dart';
import 'package:tekartik_io_auth_utils/src/io_auth_utils_memory.dart';
import 'package:tekartik_io_utils/io_utils_import.dart';

// Copyright (c) 2017, alex. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

class AuthCommonParamMock implements AuthCommonParam {
  @override
  Future<Map> getClientIdMap() async {
    return <String, Object?>{
      'client_id': 'mock_client_id',
      'client_secret': 'mock_client_secret'
    };
  }

  @override
  Future<Map?> getCredentialsMap() {
    throw UnimplementedError();
  }

  @override
  Future<void> promptUserConsent(String url) {
    // TODO: implement promptUserConsent
    throw UnimplementedError();
  }

  @override
  Future<void> setCredentialsMap(Map map) {
    throw UnimplementedError();
  }
}

void main() {
  group('io_auth_utils_common', () {
    test('load', () async {
      var info = await AuthClientInfoCommon.load(param: AuthCommonParamMock());
      expect(info.clientId, 'mock_client_id');
    });
  });
}
