import 'package:equatable/equatable.dart';

class Response extends Equatable {
  final int statusCode;
  final dynamic data;
  final Map<String, String> header;
  const Response({
    required this.statusCode,
    required this.data,
    required this.header,
  });

  @override
  String toString() =>
      'CleanResponse(statusCode: $statusCode, body: $data, header: $header)';

  @override
  List<Object> get props => [statusCode, data, header];

  Response copyWith({
    int? statusCode,
    dynamic body,
    Map<String, String>? header,
  }) {
    return Response(
      statusCode: statusCode ?? this.statusCode,
      data: body ?? data,
      header: header ?? this.header,
    );
  }
}
