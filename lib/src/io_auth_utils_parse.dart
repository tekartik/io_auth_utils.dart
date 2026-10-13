import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;

/// Client id and secret read from a client id map, null when missing.
///
/// Handles this format:
/// ```yaml
/// # Get the data from google cloud console, new Client ID for Desktop application
/// client_id: 2**************************6.apps.googleusercontent.com
/// client_secret: v************g
/// ```
///
/// and the json downloaded from the console:
/// ```json
/// {
///   "installed": {
///     "client_id": "83xxxxxom",
///     "project_id": "soxxxxxo",
///     "auth_uri": "https://accounts.google.com/o/oauth2/auth",
///     "token_uri": "https://oauth2.googleapis.com/token",
///     "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
///     "client_secret": "GOxxxxxIi",
///     "redirect_uris": ["http://localhost"]
///   }
/// }
/// ```
({String? clientId, String? clientSecret}) parseClientIdMap(Map map) {
  var clientId = map['client_id'] as String?;
  if (clientId != null) {
    return (clientId: clientId, clientSecret: map['client_secret'] as String?);
  }
  var installedMap = map['installed'] as Map?;
  if (installedMap != null) {
    clientId = installedMap['client_id'] as String?;
    if (clientId != null) {
      return (
        clientId: clientId,
        clientSecret: installedMap['client_secret'] as String?,
      );
    }
  }
  return (clientId: null, clientSecret: null);
}

/// Client id info as text, the secret redacted.
String clientIdInfoToString(String clientId, String? clientSecret) => {
  'clientId': clientId,
  'clientSecret': clientSecret == null ? null : '<redacted>',
}.toString();

/// Access credentials read from a saved credentials map.
///
/// A refresh token saved as the text `null` (written by older versions when
/// there was no refresh token) is read as null.
auth.AccessCredentials accessCredentialsFromMap(Map map, List<String> scopes) {
  var refreshToken = map['refresh_token'] as String?;
  if (refreshToken == 'null') {
    refreshToken = null;
  }
  return auth.AccessCredentials(
    auth.AccessToken(
      map['token_type'] as String,
      map['token_data'] as String,
      DateTime.parse(map['token_expiry'] as String),
    ),
    refreshToken,
    scopes,
  );
}

/// Access credentials as a map to save (a missing refresh token stays null).
Map<String, Object?> accessCredentialsToMap(
  auth.AccessCredentials accessCredentials,
  List<String> scopes,
) => {
  'token_type': accessCredentials.accessToken.type,
  'token_data': accessCredentials.accessToken.data,
  'token_expiry': '${accessCredentials.accessToken.expiry}',
  'refresh_token': accessCredentials.refreshToken,
  'scopes': scopes,
};

/// Saved [accessCredentials] that can still be used, null otherwise.
///
/// Without a refresh token they cannot be refreshed: once expired a new login
/// is needed.
auth.AccessCredentials? usableAccessCredentials(
  auth.AccessCredentials? accessCredentials,
) {
  if (accessCredentials != null &&
      accessCredentials.refreshToken == null &&
      accessCredentials.accessToken.hasExpired) {
    return null;
  }
  return accessCredentials;
}

/// An authenticated client, refreshing the access token when there is a
/// refresh token.
http.Client authClientFromCredentials(
  auth.ClientId clientId,
  auth.AccessCredentials accessCredentials,
  http.Client baseClient,
) {
  if (accessCredentials.refreshToken == null) {
    // autoRefreshingClient throws without a refresh token
    return auth.authenticatedClient(baseClient, accessCredentials);
  }
  return auth.autoRefreshingClient(clientId, accessCredentials, baseClient);
}
