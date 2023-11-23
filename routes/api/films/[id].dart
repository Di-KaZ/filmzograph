import 'package:dart_frog/dart_frog.dart';
import 'package:drift/drift.dart';
import 'package:filmzy/database.dart';
import 'package:filmzy/utils.dart';

/// @Allow(GET,DELETE,PUT)
Future<Response> onRequest(RequestContext context, String filmId) async {
  final id = int.tryParse(filmId);

  if (id == null) return Response.json(statusCode: 400);

  return switch (context.request.method) {
    HttpMethod.get => _get(context, id),
    HttpMethod.delete => _delete(context, id),
    HttpMethod.put => _put(context, id),
    _ => notImplemented,
  };
}

Future<Response> _put(RequestContext context, int id) async {
  final json = await context.request.json();

  if (json is! Map) return malformedJson;

  DateTime? date;
  final name = json['name'] as String?;
  final description = json['description'] as String?;
  final releasedAt = json['releasedAt'] as String?;

  /// small check on the date if it has the right format
  if (releasedAt != null) {
    date = DateTime.tryParse(releasedAt);
    if (date == null) return malformedJson;
  } else {
    date = null;
  }

  final db = context.read<AppDatabase>();
  final query = db.update(db.film)..where((tbl) => tbl.id.equals(id));
  final res = await query.writeReturning(
    FilmCompanion(
      id: Value(id),
      name: name != null ? Value(name) : const Value.absent(),
      description:
          description != null ? Value(description) : const Value.absent(),
      releaseDate: date != null ? Value(date) : const Value.absent(),
    ),
  );

  final modifiedFilm = res.firstOrNull;

  if (modifiedFilm != null) return Response.json(body: modifiedFilm.toJson());

  return notFound;
}

Future<Response> _delete(RequestContext context, int id) async {
  final db = context.read<AppDatabase>();
  final query = db.delete(db.film)..where((tbl) => tbl.id.equals(id));

  final deletedFilm = (await query.goAndReturn()).firstOrNull;

  if (deletedFilm == null) return notFound;

  return Response.json(body: deletedFilm.toJson());
}

/// Returns a [Film] from the databse via its id
Future<Response> _get(RequestContext context, int filmId) async {
  final db = context.read<AppDatabase>();
  final query = db.select(db.film)..where((film) => film.id.equals(filmId));

  final film = await query.getSingleOrNull();

  if (film != null) {
    return Response.json(body: film.toJson());
  }

  return notFound;
}
