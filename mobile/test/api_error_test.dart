import 'package:bookie_ai/data/services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('serverErrorMessage', () {
    test('prefers message over the HTTP status name', () {
      expect(
        serverErrorMessage({
          'statusCode': 401,
          'message': 'Invalid credentials',
          'error': 'Unauthorized',
        }),
        'Invalid credentials',
      );
    });

    test('joins validation message lists', () {
      expect(
        serverErrorMessage({
          'statusCode': 400,
          'message': ['email must be an email', 'password is too short'],
          'error': 'Bad Request',
        }),
        'Email must be an email\nPassword is too short',
      );
    });

    test('falls back to error, then null', () {
      expect(serverErrorMessage({'error': 'Conflict'}), 'Conflict');
      expect(serverErrorMessage('not a map'), isNull);
      expect(serverErrorMessage(null), isNull);
    });
  });

  group('friendlyError', () {
    test('uses the server message from a DioException response', () {
      final options = RequestOptions(path: '/auth/login');
      final error = DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 401,
          data: {'message': 'Invalid credentials', 'error': 'Unauthorized'},
        ),
      );
      expect(friendlyError(error), 'Invalid credentials');
    });

    test('strips the Exception prefix', () {
      expect(friendlyError(Exception('Boom')), 'Boom');
    });
  });
}
