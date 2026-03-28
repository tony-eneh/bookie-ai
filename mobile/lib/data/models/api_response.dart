class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? error;

  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json)? fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'] as bool? ?? true,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      message: json['message'] as String?,
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson(Object? Function(T value)? toJsonT) {
    return {
      'success': success,
      if (data != null)
        'data': toJsonT != null ? toJsonT(data as T) : data,
      if (message != null) 'message': message,
      if (error != null) 'error': error,
    };
  }

  bool get isSuccess => success && error == null;
  bool get isError => !success || error != null;

  @override
  String toString() =>
      'ApiResponse(success: $success, message: $message, error: $error)';
}

class PaginatedResponse<T> {
  final List<T> data;
  final int total;
  final int page;
  final int limit;

  const PaginatedResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) fromJsonT,
  ) {
    return PaginatedResponse(
      data: (json['data'] as List<dynamic>)
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
    );
  }

  Map<String, dynamic> toJson(
      Map<String, dynamic> Function(T value) toJsonT) {
    return {
      'data': data.map(toJsonT).toList(),
      'total': total,
      'page': page,
      'limit': limit,
    };
  }

  bool get hasMore => page * limit < total;
  int get totalPages => (total / limit).ceil();

  @override
  String toString() =>
      'PaginatedResponse(total: $total, page: $page, limit: $limit, items: ${data.length})';
}
