import 'dart:math';

import 'package:dart_frog/dart_frog.dart';
import 'package:drift/drift.dart';
import 'package:filmzy/database.dart';
import 'package:filmzy/utils.dart';
import 'package:path/path.dart';

/// @Query(pageSize)
/// @Allow(GET)
/// request a films page
Future<Response> onRequest(RequestContext context, String num) async {
  final page = int.tryParse(num);

  final parameters = context.request.uri.queryParameters;

  final pageSize = min(int.tryParse(parameters['pageSize'] ?? '') ?? 20, 20);
  final realisatorName = parameters['realisatorName'];
  final actorName = parameters['actorName'];

  if (realisatorName != null && actorName != null) {
    return Response.json(
      body: {
        'message': "can't have realisatorName and actorName as the same time",
      },
    );
  }

  if (page == null) return Response.json(statusCode: 400);

  return switch (context.request.method) {
    HttpMethod.get => _get(context, page, pageSize, realisatorName, actorName),
    _ => notImplemented,
  };
}

Future<Response> _get(
  RequestContext context,
  int page,
  int pageSize,
  String? realisatorName,
  String? actorName,
) async {
  final db = context.read<AppDatabase>();

  /// NOTE: this is pure evil, do not use drift db ever again
  /// in fact, do not use dart to make web server ever again
  /// still not work as intended better write RAW sql
  final realisatorOfQuery = Subquery(
    db.select(db.peopleRealisatorOf).join([
      innerJoin(
        db.people,
        db.people.id.equalsExp(db.peopleRealisatorOf.peopleId),
      ),
    ])
      ..where(
        realisatorName == null && actorName == null
            ? db.people.name.like('%$realisatorName%')
            : const CustomExpression('1 = 1'),
      ),
    'realisators',
  );

  final actedInQuery = Subquery(
    db.select(db.peopleActedIn).join([
      innerJoin(
        db.people,
        db.people.id.equalsExp(db.peopleActedIn.peopleId),
      ),
    ])
      ..where(
        realisatorName == null && actorName == null
            ? db.people.name.like('%$actorName%')
            : const CustomExpression('1 = 1'),
      ),
    'realisators',
  );

  final query = db.select(db.film).join(
    [
      innerJoin(
        realisatorOfQuery,
        realisatorOfQuery
            .ref(db.peopleRealisatorOf.filmId)
            .equalsExp(db.film.id),
        useColumns: false,
      ),
      innerJoin(
        actedInQuery,
        actedInQuery.ref(db.peopleActedIn.filmId).equalsExp(db.film.id),
        useColumns: false,
      ),
    ],
  )
    ..limit(pageSize, offset: (page - 1) * pageSize)
    ..groupBy([db.film.id]);

  final films = await query.get();

  return Response.json(
    body: films.map((e) => e.readTable(db.film).toJson()).toList(),
  );
}
