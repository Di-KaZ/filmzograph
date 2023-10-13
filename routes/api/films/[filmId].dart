import 'package:dart_frog/dart_frog.dart';
import 'package:filmzy/database.dart';

Future<Response> onRequest(RequestContext context, String filmId) async {
  final id = int.tryParse(filmId);

  if (id == null) {
    // TODO: error codes
    return Response.json(statusCode: 400);
  }

  switch (context.request.method) {
    case HttpMethod.get:
      return _handleGet(context, id);
    default:
      break;
  }

  return Response(body: 'post id: $filmId');
}

Future<Response> _handleGet(RequestContext context, int filmId) async {
  final db = context.read<AppDatabase>();
  final query = db.select(db.film)..where((film) => film.id.equals(filmId));

  final film = await query.getSingleOrNull();

  if (film != null) {
    return Response.json(body: film.toJson());
  }
  return Response.json(statusCode: 404);
}
