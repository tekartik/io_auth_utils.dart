import 'package:path/path.dart';
import 'package:tekartik_io_utils/io_utils_import.dart';
import 'package:yaml/yaml.dart';

import 'io_auth_utils_memory.dart';

class AuthCommonParamFile implements AuthCommonParam {
  AuthCommonParamFile(
      {this.clientIdMap,
      required this.clientIdPath,
      required this.credentialsPath});

  final String? clientIdPath;
  final String? credentialsPath;
  Map? clientIdMap;

  @override
  Future<Map> getClientIdMap() async {
    if (clientIdMap == null) {
      var clientIdPath = this.clientIdPath ?? join('.local', 'client_id.yaml');

      if (File(clientIdPath).existsSync()) {
        clientIdMap = loadYaml(await File(clientIdPath).readAsString()) as Map?;
      } else {
        stderr.write(
            "need secret file here: $clientIdPath to download from <https://console.cloud.google.com/apis/credentials> section 'OAuth 2.0 client IDs");
        throw StateError('no client id');
      }
      if (clientIdMap == null) {
        throw StateError('invalid client id as $clientIdPath');
      }
    }
    return clientIdMap!;
  }

  String get _credentialsPath =>
      credentialsPath ?? join('.local', 'access_credentials.yaml');

  @override
  Future<Map?> getCredentialsMap() async {
    var file = File(_credentialsPath);
    if (!file.existsSync()) {
      stderr.writeln('Credential file not found, logging in');
    } else {
      final yaml = loadYaml(file.readAsStringSync()) as Map;
      return yaml;
    }
    return null;
  }

  @override
  Future<void> promptUserConsent(String url) async {
    ioPromptUser(url);
  }

  @override
  Future<void> setCredentialsMap(Map map) async {
    var file = File(_credentialsPath);
    file.parent.createSync(recursive: true);

    await file.writeAsString(jsonPretty(map)!);
  }
}

void ioPromptUser(String url) {
  print('Please go to the following URL and grant access:');
  print('  => $url');
  print('');
}
