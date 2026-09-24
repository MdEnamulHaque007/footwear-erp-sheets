// lib/services/sheet_client.dart
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import '../core/errors/sheet_exceptions.dart';

/// Downloads public Google Sheets CSV using an injected HTTP client.
class SheetClient {
  /// Creates a downloader; ownership of [client] remains with the caller.
  const SheetClient({
    required http.Client client,
    this.timeout = AppConstants.requestTimeout,
    this.retryDelay = const Duration(milliseconds: 200),
  }) : _client = client;

  final http.Client _client;

  /// Maximum duration for a single HTTP attempt.
  final Duration timeout;

  /// Delay before retrying a server response.
  final Duration retryDelay;

  /// Fetches strictly decoded UTF-8, retrying 5xx at most twice.
  Future<String> fetchCsv(Uri uri) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final response = await _client.get(uri).timeout(timeout);
        if (response.statusCode >= 500 && attempt < 2) {
          if (retryDelay > Duration.zero)
            await Future<void>.delayed(retryDelay);
          continue;
        }
        if (response.statusCode != 200) {
          throw SheetNetworkException(
              'Google Sheets returned HTTP ${response.statusCode}.',
              uri: uri);
        }
        try {
          return utf8.decode(response.bodyBytes);
        } on FormatException catch (error) {
          throw SheetParseException('CSV is not valid UTF-8.',
              cause: error, uri: uri);
        }
      } on SheetException {
        rethrow;
      } on TimeoutException catch (error) {
        throw SheetTimeoutException('Google Sheets request timed out.',
            cause: error, uri: uri);
      } on http.ClientException catch (error) {
        throw SheetNetworkException('Could not connect to Google Sheets.',
            cause: error, uri: uri);
      } catch (error) {
        throw SheetNetworkException('Unexpected HTTP transport failure.',
            cause: error, uri: uri);
      }
    }
    throw SheetNetworkException('CSV request failed.', uri: uri);
  }
}
