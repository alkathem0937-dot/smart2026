/// Custom exception for API errors with structured error codes.
class ApiException implements Exception {
  final String message;
  final ApiErrorCode code;
  final int? statusCode;
  final Map<String, dynamic>? fieldErrors;

  const ApiException({
    required this.message,
    this.code = ApiErrorCode.unknown,
    this.statusCode,
    this.fieldErrors,
  });

  /// Human-readable Arabic message for display in UI.
  String get userMessage {
    switch (code) {
      case ApiErrorCode.timeout:
        return 'انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى.';
      case ApiErrorCode.noConnection:
        return 'لا يوجد اتصال بالخادم. تأكد من تشغيل الخادم واتصال الإنترنت.';
      case ApiErrorCode.connectionRefused:
        return 'تم رفض الاتصال. تأكد من تشغيل الخادم.';
      case ApiErrorCode.unauthorized:
        return 'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى.';
      case ApiErrorCode.forbidden:
        return 'ليس لديك صلاحية للوصول إلى هذا المورد.';
      case ApiErrorCode.notFound:
        return 'المورد المطلوب غير موجود.';
      case ApiErrorCode.validation:
        return message;
      case ApiErrorCode.serverError:
        return 'حدث خطأ في الخادم. يرجى المحاولة لاحقاً.';
      case ApiErrorCode.invalidCredentials:
        return 'اسم المستخدم أو كلمة المرور غير صحيحة.';
      case ApiErrorCode.unknown:
        return message.isNotEmpty ? message : 'حدث خطأ غير متوقع.';
    }
  }

  @override
  String toString() => 'ApiException($code): $message';
}

/// Structured error codes for programmatic handling.
enum ApiErrorCode {
  timeout,
  noConnection,
  connectionRefused,
  unauthorized,
  forbidden,
  notFound,
  validation,
  serverError,
  invalidCredentials,
  unknown,
}
