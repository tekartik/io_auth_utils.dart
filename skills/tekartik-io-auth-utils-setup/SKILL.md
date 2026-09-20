---
name: tekartik-io-auth-utils-setup
description: >-
  Use when a Dart VM / command line tool must call Google APIs as a user with
  package:tekartik_io_auth_utils: initAuthClient(scopes:, clientIdPath:,
  clientIdMap:, credentialsPath:) returning an authenticated http.Client for
  googleapis (Oauth2Api, PeopleServiceApi, DriveApi), the .local/client_id.yaml
  OAuth desktop client id file and .local/access_credentials.yaml token cache,
  emailScope / userInfoProfileScope, AuthClientInfo.load, and the console
  "go to this URL and grant access" consent flow (obtainAccessCredentialsViaUserConsent,
  autoRefreshingClient). Also covers the AuthCommonParam /
  initAuthClientWithParam hook for a custom credentials store.
---

# tekartik_io_auth_utils: Google OAuth for io apps

`tekartik_io_auth_utils` wraps `googleapis_auth` for command line / desktop
Dart apps: it reads an OAuth **Desktop application** client id from a local
file, runs the console user-consent flow once, caches the access and refresh
tokens on disk, and returns a self-refreshing `http.Client` you pass to any
`googleapis` API class. It is `dart:io` only (no web, no Flutter web) and is
meant for developer tools and scripts, not for shipping to end users.

## Guidelines

* Dependency (git only, not published on pub.dev). Add `googleapis` yourself
  for the API classes you call:
  ```yaml
  dependencies:
    tekartik_io_auth_utils:
      git:
        url: https://github.com/tekartik/io_auth_utils.dart
      version: '>=0.3.0'
    googleapis: ">=1.2.0"
  ```
* One public library: `package:tekartik_io_auth_utils/io_auth_utils.dart`,
  exporting `initAuthClient`, `AuthClientInfo`, `emailScope`,
  `userInfoProfileScope` and `accessCredentialsFilename`
  (`'access_credentials.yaml'`).
* Normal use is a single call,
  `await initAuthClient(scopes: [userInfoProfileScope])`.
  It returns a `package:http` `Client` (an `AutoRefreshingAuthClient`) valid
  for those scopes. Hand it straight to a `googleapis` constructor
  (`Oauth2Api(client)`, `PeopleServiceApi(client)`, ...) and `close()` it when
  the tool ends.
* Client id file: by default `.local/client_id.yaml`, overridable with
  `clientIdPath:`. Two shapes are accepted, so you can paste either the two
  fields or the JSON downloaded from the Google Cloud Console
  (`OAuth 2.0 Client IDs` > `Desktop app`):
  ```yaml
  # .local/client_id.yaml
  client_id: <your-client-id>.apps.googleusercontent.com
  client_secret: <your-client-secret>
  ```
  ```json
  { "installed": { "client_id": "<id>", "client_secret": "<secret>" } }
  ```
  `clientIdMap:` passes the same map in memory instead (tests, or a secret read
  from the environment); it wins over `clientIdPath`. A missing file writes an
  explanation to `stderr` and throws `StateError('no client id')`.
  Never commit these files: keep `.local/` in `.gitignore`.
* Token cache: by default `.local/access_credentials.yaml`, overridable with
  `credentialsPath:`. It holds `token_type`, `token_data`, `token_expiry`,
  `refresh_token` and the `scopes` list (written as JSON, read back with
  `loadYaml`). Parent directories are created. Delete the file to force a new
  login.
* Scopes are part of the cache: if the stored `scopes` set differs from the one
  you pass, the tool logs `scopes do not match` and re-runs the consent flow.
  Keep the scope list in one constant so every entry point asks for the same
  set. Use `userInfoProfileScope` / `emailScope` for identity, and the API
  constants from `googleapis` (`PeopleServiceApi.contactsReadonlyScope`,
  `DriveApi.driveReadonlyScope`, ...) for the rest.
* First run is interactive: the URL is printed on `stdout`
  (`Please go to the following URL and grant access:`) and the process waits
  for the redirect. Never call `initAuthClient` from a server, a CI job or a
  test that must not block; pre-provision the credentials file instead.
* When `userInfoProfileScope` is in the scopes, the cached credentials are
  probed with `Oauth2Api.userinfo.get()`; the user info JSON is printed and an
  `invalid_grant` answer transparently triggers a new login. Expect that
  output on stdout.
* `verbose:` is accepted by `initAuthClient` but currently unused; do not rely
  on it for logging.
* `AuthClientInfo` is the older compat API, still exported: `await
  AuthClientInfo.load(filePath: path, map: map)` returns `null` for an
  unusable map and throws `FileSystemException` when the file does not exist;
  `info.getClient(scopes, packageName: ..., localDirPath: ..., credentialsPath: ...)`
  does the same consent dance with a per-package
  `.local/<packageName>/access_credentials.yaml`. It ignores stored scopes.
  Prefer `initAuthClient` in new code and use `AuthClientInfo` only to read a
  client id file (`clientId`, `clientSecret`, `authClientId`).
* Custom credentials store (keychain, sembast, memory): implement
  `AuthCommonParam` (`getClientIdMap`, `getCredentialsMap`,
  `setCredentialsMap`, `promptUserConsent`) and call
  `initAuthClientWithParam(scopes: ..., param: ...)`. Both live in
  `package:tekartik_io_auth_utils/src/io_auth_utils_memory.dart`, so this is an
  implementation import (`// ignore: implementation_imports`) that may change;
  the file-based implementation `AuthCommonParamFile` and the `ioPromptUser`
  console prompt are in `src/io_auth_utils_file.dart`.
* Testing: the only offline-testable parts are the client id parsing
  (`AuthClientInfo.load`, `AuthClientInfoCommon.load`) with a fake
  `AuthCommonParam`. Anything that calls `getClient` hits the network.

## Examples

### Who am I (default `.local` paths)

```dart
import 'package:googleapis/oauth2/v2.dart';
import 'package:tekartik_io_auth_utils/io_auth_utils.dart';
import 'package:tekartik_io_utils/io_utils_import.dart';

Future<void> main() async {
  // First run prints a consent url, then caches tokens in
  // .local/access_credentials.yaml
  var client = await initAuthClient(scopes: [emailScope, userInfoProfileScope]);
  try {
    var userInfo = await Oauth2Api(client).userinfo.get();
    stdout.writeln(jsonPretty(userInfo.toJson()));
  } finally {
    client.close();
  }
}
```

### Explicit paths, one scope list, a googleapis call

```dart
import 'package:googleapis/people/v1.dart';
import 'package:path/path.dart';
import 'package:tekartik_io_auth_utils/io_auth_utils.dart';
import 'package:tekartik_io_utils/io_utils_import.dart';

/// Keep the scopes in one place: changing them forces a new login.
const scopes = [
  'https://www.googleapis.com/auth/userinfo.profile',
  PeopleServiceApi.contactsReadonlyScope,
];

Future<void> main() async {
  var client = await initAuthClient(
    scopes: scopes,
    clientIdPath: join('.local', 'my_tool', 'client_id.yaml'),
    credentialsPath: join('.local', 'my_tool', 'access_credentials.yaml'),
  );
  try {
    var api = PeopleServiceApi(client);
    var me = await api.people.get('people/me', personFields: 'names');
    stdout.writeln(jsonPretty(me.toJson()));
  } finally {
    client.close();
  }
}
```

### Client id from the environment instead of a file

```dart
import 'package:http/http.dart';
import 'package:tekartik_io_auth_utils/io_auth_utils.dart';
import 'package:tekartik_io_utils/io_utils_import.dart';

/// [Client] is `package:http`'s client.
Future<Client> authClientFromEnv(List<String> scopes) async {
  var id = Platform.environment['GOOGLE_CLIENT_ID'];
  var secret = Platform.environment['GOOGLE_CLIENT_SECRET'];
  if (id == null || secret == null) {
    throw StateError('set GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET');
  }
  return await initAuthClient(
    scopes: scopes,
    // clientIdMap wins over any client id file
    clientIdMap: <String, Object?>{'client_id': id, 'client_secret': secret},
  );
}
```

### Reading a client id file without logging in

```dart
import 'package:path/path.dart';
import 'package:tekartik_io_auth_utils/io_auth_utils.dart';
import 'package:tekartik_io_utils/io_utils_import.dart';

Future<void> main() async {
  var path = join('.local', 'client_id.yaml');
  try {
    var info = await AuthClientInfo.load(filePath: path);
    if (info == null) {
      stderr.writeln('$path is not a client id file');
      return;
    }
    stdout.writeln('client id: ${info.clientId}'); // never log the secret
  } on FileSystemException catch (_) {
    stderr.writeln('missing $path, download it from the cloud console');
  }
}
```

### Custom credentials store (implementation import)

```dart
// ignore: implementation_imports
import 'package:tekartik_io_auth_utils/src/io_auth_utils_memory.dart';
import 'package:tekartik_io_utils/io_utils_import.dart';

/// Keeps the tokens in memory only: one login per process.
class MemoryAuthParam implements AuthCommonParam {
  MemoryAuthParam({required this.clientId, required this.clientSecret});
  final String clientId;
  final String clientSecret;
  Map? _credentials;

  @override
  Future<Map> getClientIdMap() async => <String, Object?>{
    'client_id': clientId,
    'client_secret': clientSecret,
  };

  @override
  Future<Map?> getCredentialsMap() async => _credentials;

  @override
  Future<void> setCredentialsMap(Map map) async => _credentials = map;

  @override
  Future<void> promptUserConsent(String url) async {
    stdout.writeln('Open this url to grant access: $url');
  }
}

Future<void> main() async {
  var client = await initAuthClientWithParam(
    scopes: ['email'],
    param: MemoryAuthParam(
      clientId: '<your-client-id>.apps.googleusercontent.com',
      clientSecret: '<your-client-secret>',
    ),
  );
  client.close();
}
```

## Common mistakes

* Using a **Web application** OAuth client: the console flow needs a *Desktop
  application* client id (or one that allows the loopback redirect).
* Committing `.local/client_id.yaml` or `.local/access_credentials.yaml`, or
  pasting a real client id / secret into source or documentation.
* Calling `initAuthClient` in a test, a CI step or a server process: it blocks
  on interactive consent when no valid cached token exists.
* Changing the scope list between runs and being surprised by a new login, or
  passing scopes in a different order across entry points (the set is compared,
  but keep one shared constant).
* Expecting `verbose: true` to log anything.
* Expecting `AuthClientInfo.load` to return `null` for a missing file: it
  throws `FileSystemException` (it returns `null` for an unusable content).
* Importing this package from web or Flutter web code, or forgetting to
  `close()` the returned client in a long-lived tool.
