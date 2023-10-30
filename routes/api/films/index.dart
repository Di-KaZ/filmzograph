import 'package:dart_frog/dart_frog.dart';
import 'package:filmzy/database.dart';
import 'package:filmzy/utils.dart';

/// @Allow(POST)
Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.post => _post(context),
    _ => notImplemented,
  };
}

Future<Response> _post(RequestContext context) async {
  final filmJson = await context.request.json();

  late FilmCompanion film;

  if (filmJson
      case {
        'name': final String name,
        'description': final String description,
        'releaseDate': final String releaseDate
      }) {
    final date = DateTime.tryParse(releaseDate);
    if (date == null) {
      return Response.json(
        statusCode: 400,
        body: {'message': 'malformed json'},
      );
    }
    film = FilmCompanion.insert(
      name: name,
      description: description,
      releaseDate: date,
    );
  } else {
    return Response.json(
      statusCode: 400,
      body: {'message': 'malformed json'},
    );
  }

  final db = context.read<AppDatabase>();

  final insertedFilm = await db.into(db.film).insertReturningOrNull(film);

  if (insertedFilm != null) {
    return Response.json(body: insertedFilm.toJson());
  }

  return Response.json(statusCode: 500);
}
