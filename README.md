# tekartik_io_auth_utils

Google OAuth for Dart command line tools: `initAuthClient` reads an OAuth
*Desktop app* client id from a local file, runs the "open this URL and grant
access" consent flow once, caches the tokens on disk and returns an
authenticated `http.Client` for the
[googleapis](https://pub.dev/packages/googleapis) API classes. Built on
[googleapis_auth](https://pub.dev/packages/googleapis_auth).

## Getting started

Not on pub.dev, add it as a git dependency (Dart SDK `^3.12.0`), with
`googleapis` for the API you call:

```yaml
dependencies:
  tekartik_io_auth_utils:
    git:
      url: https://github.com/tekartik/io_auth_utils.dart
  googleapis: any
```

1. In the [Google Cloud console](https://console.cloud.google.com/apis/credentials),
   create an *OAuth client ID* of type *Desktop app*, and enable the APIs you
   call.
2. Save it as `.local/client_id.yaml` in your tool's folder (or the JSON
   downloaded from the console), and keep `.local/` out of git:

   ```yaml
   client_id: <your-client-id>.apps.googleusercontent.com
   client_secret: <your-client-secret>
   ```
3. Call it:

```dart
import 'package:googleapis/oauth2/v2.dart';
import 'package:tekartik_io_auth_utils/io_auth_utils.dart';

Future<void> main() async {
  // First run: prints a URL to open, then caches the tokens in
  // .local/access_credentials.yaml.
  var client = await initAuthClient(scopes: [emailScope]);
  try {
    var userInfo = await Oauth2Api(client).userinfo.get();
    print(userInfo.email);
  } finally {
    client.close();
  }
}
```

`dart:io` only: Dart VM command line tools and desktop scripts, not the web
nor Flutter apps (use a Google sign in package there). See
[example/io_auth_utils_example.dart](example/io_auth_utils_example.dart).

## What to use

* `initAuthClient(scopes: ..., clientIdPath: ..., clientIdMap: ...,
  credentialsPath: ...)`: the client. Defaults: `.local/client_id.yaml` and
  `.local/access_credentials.yaml`, relative to the current folder.
  `clientIdMap` (for example from environment variables) wins over the
  file.
* `emailScope`, `userInfoProfileScope`, and the scopes of the `googleapis`
  classes (`DriveApi.driveReadonlyScope`...).
* `AuthClientInfo.load(filePath: ...)`: reads a client id file
  (`clientId`, `clientSecret`); its `getClient` is the older API.

## Common pitfalls

* The first run, and any run after a scope change, is interactive: it waits
  for the browser redirect. Do not call it from a server, a CI job or a test.
* The cached scopes must be the same set: another list triggers a new
  login. Keep the list in one constant.
* With `userInfoProfileScope`, the cached tokens are checked at start (the
  user info JSON is printed) and a revoked grant starts a new login. Without
  it, a revoked refresh token makes every call fail: delete the cache file.
* The cache file holds a refresh token, written with the default file mode
  (readable by the other accounts of the machine with the usual umask):
  `chmod 600` it on a shared machine.
* Never commit `.local/`, nor paste a client secret or token in code or
  docs. `toString()` of the client info redacts the secret.
* `verbose` is accepted but unused.

## Agent skills

[skills/tekartik-io-auth-utils-setup](skills/tekartik-io-auth-utils-setup/SKILL.md).
