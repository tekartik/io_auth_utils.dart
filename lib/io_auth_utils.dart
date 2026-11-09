// Copyright (c) 2017, alex. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

/// Google OAuth for Dart command line tools ([initAuthClient]): a desktop
/// client id read from a file, a console consent flow, tokens cached on disk.
library;

export 'src/io_auth_utils.dart' show initAuthClient;
export 'src/io_auth_utils_compat.dart'
    show
        AuthClientInfo,
        accessCredentialsFilename,
        emailScope,
        userInfoProfileScope;
