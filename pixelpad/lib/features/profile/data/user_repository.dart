import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../domain/entities/user_profile.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class AuthSession {
  final String accessToken;
  final String tokenType;
  final int? expiresIn;
  final UserProfile user;

  const AuthSession({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });
}

abstract class UserDataSource {
  Future<UserProfile> fetchCurrentUser({
    required String accessToken,
    required String tokenType,
  });
  Future<UserProfile> saveUser({
    required UserProfile data,
    required String accessToken,
    required String tokenType,
  });
  Future<AuthSession> loginUser({
    required String phone,
    required String password,
  });
  Future<AuthSession> registerUser({
    required String phone,
    required String password,
  });
}

class BackendUserDataSource implements UserDataSource {
  BackendUserDataSource({
    http.Client? client,
    this.baseUrl = 'http://backend.edmounds.top',
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  @override
  Future<UserProfile> fetchCurrentUser({
    required String accessToken,
    required String tokenType,
  }) async {
    if (_isMockSession(accessToken, tokenType)) {
      final response = await _client.get(
        Uri.parse('$baseUrl/users/$accessToken'),
      );
      if (response.statusCode != 200) {
        throw _toApiException(
          response,
          defaultMessage: 'Failed to load current user',
        );
      }
      final data = _decodeJsonMap(response.body);
      return UserProfile.fromMap(data);
    }
    final response = await _client.get(
      Uri.parse('$baseUrl/users/me'),
      headers: _authHeaders(accessToken: accessToken, tokenType: tokenType),
    );
    if (response.statusCode != 200) {
      throw _toApiException(
        response,
        defaultMessage: 'Failed to load current user',
      );
    }
    final data = _decodeJsonMap(response.body);
    return UserProfile.fromMap(data);
  }

  @override
  Future<UserProfile> saveUser({
    required UserProfile data,
    required String accessToken,
    required String tokenType,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'phone': data.phone,
      'username': data.username,
      'email': data.email,
      'birthday': _formatDate(data.birthday),
      'mbti': data.mbti,
      'avatarMode': data.avatarMode.name,
    };
    if (data.password.trim().isNotEmpty) {
      payload['password'] = data.password;
    }

    final http.Response response;
    if (_isMockSession(accessToken, tokenType)) {
      response = await _client.put(
        Uri.parse('$baseUrl/users/$accessToken'),
        headers: _jsonHeaders(),
        body: jsonEncode(payload),
      );
    } else {
      response = await _client.put(
        Uri.parse('$baseUrl/users/me'),
        headers: _authHeaders(
          accessToken: accessToken,
          tokenType: tokenType,
          withJsonContentType: true,
        ),
        body: jsonEncode(payload),
      );
    }
    if (response.statusCode != 200) {
      throw _toApiException(
        response,
        defaultMessage: 'Failed to save current user',
      );
    }
    final Map<String, dynamic> updated = _decodeJsonMap(response.body);
    return UserProfile.fromMap(updated);
  }

  @override
  Future<AuthSession> loginUser({
    required String phone,
    required String password,
  }) async {
    final http.Response response = await _client.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _jsonHeaders(),
      body: jsonEncode(<String, String>{'phone': phone, 'password': password}),
    );
    if (response.statusCode == 200) {
      return _parseAuthSession(response.body);
    }
    if (response.statusCode == 404 || response.statusCode == 405) {
      final http.Response fallback = await _client.post(
        Uri.parse('$baseUrl/login'),
        headers: _jsonHeaders(),
        body: jsonEncode(<String, String>{'phone': phone, 'password': password}),
      );
      if (fallback.statusCode != 200) {
        throw _toApiException(
          fallback,
          defaultMessage: 'Failed to login user',
        );
      }
      return _parseAuthSession(fallback.body);
    }
    throw _toApiException(response, defaultMessage: 'Failed to login user');
  }

  @override
  Future<AuthSession> registerUser({
    required String phone,
    required String password,
  }) async {
    final http.Response response = await _client.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _jsonHeaders(),
      body: jsonEncode(<String, String>{'phone': phone, 'password': password}),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return _parseAuthSession(response.body);
    }
    if (response.statusCode == 404 || response.statusCode == 405) {
      final http.Response fallback = await _client.post(
        Uri.parse('$baseUrl/register'),
        headers: _jsonHeaders(),
        body: jsonEncode(<String, String>{'phone': phone, 'password': password}),
      );
      if (fallback.statusCode != 201 && fallback.statusCode != 200) {
        throw _toApiException(
          fallback,
          defaultMessage: 'Failed to register user',
        );
      }
      return _parseAuthSession(fallback.body);
    }
    throw _toApiException(response, defaultMessage: 'Failed to register user');
  }

  Map<String, String> _jsonHeaders() => <String, String>{
    'Content-Type': 'application/json',
  };

  Map<String, String> _authHeaders({
    required String accessToken,
    required String tokenType,
    bool withJsonContentType = false,
  }) {
    final String resolvedTokenType = tokenType.isEmpty ? 'Bearer' : tokenType;
    final Map<String, String> headers = <String, String>{
      'Authorization': '$resolvedTokenType $accessToken',
    };
    if (withJsonContentType) {
      headers['Content-Type'] = 'application/json';
    }
    return headers;
  }

  AuthSession _parseAuthSession(String rawBody) {
    final Map<String, dynamic> data = _decodeJsonMap(rawBody);
    if (data.containsKey('access_token') || data.containsKey('token_type')) {
      final Map<String, dynamic> userMap = data['user'] is Map<String, dynamic>
          ? data['user'] as Map<String, dynamic>
          : <String, dynamic>{};
      return AuthSession(
        accessToken: data['access_token'] as String? ?? '',
        tokenType: data['token_type'] as String? ?? 'Bearer',
        expiresIn: (data['expires_in'] as num?)?.toInt(),
        user: UserProfile.fromMap(userMap),
      );
    }
    if (data.isNotEmpty) {
      final UserProfile user = UserProfile.fromMap(data);
      return AuthSession(
        accessToken: user.id.toString(),
        tokenType: 'Mock',
        expiresIn: null,
        user: user,
      );
    }
    final Map<String, dynamic> userMap = data['user'] is Map<String, dynamic>
        ? data['user'] as Map<String, dynamic>
        : <String, dynamic>{};
    return AuthSession(
      accessToken: data['access_token'] as String? ?? '',
      tokenType: data['token_type'] as String? ?? 'Bearer',
      expiresIn: (data['expires_in'] as num?)?.toInt(),
      user: UserProfile.fromMap(userMap),
    );
  }

  ApiException _toApiException(
    http.Response response, {
    required String defaultMessage,
  }) {
    final Map<String, dynamic> map = _decodeJsonMap(response.body);
    final String detail =
        map['detail'] as String? ??
        map['error'] as String? ??
        map['message'] as String? ??
        defaultMessage;
    return ApiException(statusCode: response.statusCode, message: detail);
  }

  bool _isMockSession(String accessToken, String tokenType) {
    return tokenType == 'Mock' && accessToken.isNotEmpty;
  }

  Map<String, dynamic> _decodeJsonMap(String body) {
    if (body.isEmpty) {
      return <String, dynamic>{};
    }
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class UserRepository {
  UserRepository({
    UserDataSource? dataSource,
    FlutterSecureStorage? secureStorage,
  }) : _dataSource = dataSource ?? BackendUserDataSource(),
       _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final UserDataSource _dataSource;
  final FlutterSecureStorage _secureStorage;

  static const String _accessTokenKey = 'auth_access_token_v1';
  static const String _tokenTypeKey = 'auth_token_type_v1';
  static const String _expiresInKey = 'auth_expires_in_v1';
  static const String _sessionUserIdKey = 'current_user_id_v1';

  Future<int?> getLoggedInUserId() async {
    final String? raw = await _secureStorage.read(key: _sessionUserIdKey);
    return int.tryParse(raw ?? '');
  }

  Future<String?> getAccessToken() async {
    final String? token = await _secureStorage.read(key: _accessTokenKey);
    if (token == null || token.isEmpty) {
      return null;
    }
    return token;
  }

  Future<String> _getTokenType() async {
    final String? tokenType = await _secureStorage.read(key: _tokenTypeKey);
    if (tokenType == null || tokenType.isEmpty) {
      return 'Bearer';
    }
    return tokenType;
  }

  Future<UserProfile?> fetchCurrentUser() async {
    final token = await getAccessToken();
    if (token == null) {
      return null;
    }
    try {
      final user = await _dataSource.fetchCurrentUser(
        accessToken: token,
        tokenType: await _getTokenType(),
      );
      await _secureStorage.write(
        key: _sessionUserIdKey,
        value: user.id.toString(),
      );
      return user;
    } on ApiException catch (err) {
      if (err.statusCode == 401) {
        await _clearSession();
        return null;
      }
      rethrow;
    }
  }

  Future<void> saveCurrentUser(UserProfile data) async {
    final token = await getAccessToken();
    if (token == null) {
      throw const ApiException(statusCode: 401, message: 'Not logged in');
    }
    try {
      final updated = await _dataSource.saveUser(
        data: data,
        accessToken: token,
        tokenType: await _getTokenType(),
      );
      await _secureStorage.write(
        key: _sessionUserIdKey,
        value: updated.id.toString(),
      );
    } on ApiException catch (err) {
      if (err.statusCode == 401) {
        await _clearSession();
      }
      rethrow;
    }
  }

  Future<UserProfile> register({
    required String phone,
    required String password,
  }) async {
    final session = await _dataSource.registerUser(
      phone: phone,
      password: password,
    );
    await _saveSession(session);
    return session.user;
  }

  Future<UserProfile> login({
    required String phone,
    required String password,
  }) async {
    final session = await _dataSource.loginUser(
      phone: phone,
      password: password,
    );
    await _saveSession(session);
    return session.user;
  }

  Future<void> logout() async {
    await _clearSession();
  }

  Future<void> _saveSession(AuthSession session) async {
    await _secureStorage.write(
      key: _accessTokenKey,
      value: session.accessToken,
    );
    await _secureStorage.write(key: _tokenTypeKey, value: session.tokenType);
    await _secureStorage.write(
      key: _expiresInKey,
      value: session.expiresIn?.toString(),
    );
    await _secureStorage.write(
      key: _sessionUserIdKey,
      value: session.user.id.toString(),
    );
  }

  Future<void> _clearSession() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _tokenTypeKey);
    await _secureStorage.delete(key: _expiresInKey);
    await _secureStorage.delete(key: _sessionUserIdKey);
  }
}
