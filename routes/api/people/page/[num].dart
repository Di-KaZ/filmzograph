import 'dart:math';

import 'package:dart_frog/dart_frog.dart';
import 'package:drift/drift.dart';
import 'package:filmzy/database.dart';
import 'package:filmzy/utils.dart';

/// @Query(pageSize)
/// @Allow(GET)
/// request a people page
Future<Response> onRequest(RequestContext context, String num) async {
  final page = int.tryParse(num);

  final parameters = context.request.uri.queryParameters;

  /// TODO: kind of ugly does we have a better way to do this
  final pageSize = min(int.tryParse(parameters['pageSize'] ?? '') ?? 20, 20);

  if (page == null) return Response.json(statusCode: 400);

  return switch (context.request.method) {
    HttpMethod.get => _get(context, page, pageSize),
    _ => notImplemented,
  };
}

Future<Response> _get(RequestContext context, int page, int pageSize) async {
  final db = context.read<AppDatabase>();
  final query = db.select(db.people)
    ..limit(pageSize, offset: (page - 1) * pageSize)
    ..orderBy([(people) => OrderingTerm(expression: people.name)]);

  final peoples = await query.get();

  return Response.json(body: peoples.map((e) => e.toJson()).toList());
}
