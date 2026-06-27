class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? detail;
  final String? code;

  ApiResponse({required this.success, this.data, this.detail, this.code});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'] as bool? ?? true,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : null,
      detail: json['detail'] as String?,
      code: json['code'] as String?,
    );
  }
}

class PaginatedResponse<T> {
  final List<T> items;
  final String? cursor;
  final bool hasMore;

  PaginatedResponse({
    required this.items,
    this.cursor,
    required this.hasMore,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    return PaginatedResponse(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => fromJsonT(e))
              .toList() ??
          [],
      cursor: json['cursor'] as String?,
      hasMore: json['has_more'] as bool? ?? false,
    );
  }
}
