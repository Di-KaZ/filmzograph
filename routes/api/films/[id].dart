import 'package:dart_frog/dart_frog.dart';
import 'package:filmzy/database.dart';
import 'package:filmzy/utils.dart';

Future<Response> onRequest(RequestContext context, String filmId) async {
  final id = int.tryParse(filmId);

  if (id == null) return Response.json(statusCode: 400);

  return switch (context.request.method) {
    HttpMethod.get => _get(context, id),
    HttpMethod.delete => _delete(context, id),
    _ => notImplemented,
  };
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
