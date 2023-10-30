import 'package:dart_frog/dart_frog.dart';
import 'package:drift/drift.dart';
import 'package:filmzy/database.dart';
import 'package:filmzy/utils.dart';

Future<Response> onRequest(RequestContext context, String peopleId) async {
  final id = int.tryParse(peopleId);

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
  final firstName = json['firstName'] as String?;
  final birthDate = json['birthDate'] as String?;
  final actedIn = json['actedIn'] as List?;
  final realisatorOf = json['realisatorOf'] as List?;

  /// small check on the date if it has the right format
  if (birthDate != null) {
    date = DateTime.tryParse(birthDate);
    if (date == null) return malformedJson;
  } else {
    date = null;
  }

  final db = context.read<AppDatabase>();
  final query = db.update(db.people)..where((tbl) => tbl.id.equals(id));
  final res = await query.writeReturning(
    PeopleCompanion(
      id: Value(id),
      name: name != null ? Value(name) : const Value.absent(),
      firstName: firstName != null ? Value(firstName) : const Value.absent(),
      birthDate: date != null ? Value(date) : const Value.absent(),
    ),
  );

  if (actedIn != null) {
    final deleteQuery = db.delete(db.peopleActedIn)
      ..where((tbl) => tbl.peopleId.equals(id));
    await deleteQuery.go();

    for (final acted in actedIn) {
      await db.into(db.peopleActedIn).insert(
            PeopleActedInCompanion.insert(
              peopleId: id,
              filmId: acted as int,
            ),
          );
    }
  }

  if (realisatorOf != null) {
    final deleteQuery = db.delete(db.peopleRealisatorOf)
      ..where((tbl) => tbl.peopleId.equals(id));
    await deleteQuery.go();

    for (final realised in realisatorOf) {
      await db.into(db.peopleRealisatorOf).insert(
            PeopleRealisatorOfCompanion.insert(
              peopleId: id,
              filmId: realised as int,
            ),
          );
    }
  }

  final modifiedPeople = res.firstOrNull;

  if (modifiedPeople != null) {
    return Response.json(body: modifiedPeople.toJson());
  }

  return notFound;
}

Future<Response> _delete(RequestContext context, int id) async {
  final db = context.read<AppDatabase>();
  final query = db.delete(db.people)..where((tbl) => tbl.id.equals(id));

  final deletedPeople = (await query.goAndReturn()).firstOrNull;

  if (deletedPeople == null) return notFound;

  return Response.json(body: deletedPeople.toJson());
}

Future<Response> _get(RequestContext context, int peopleId) async {
  final db = context.read<AppDatabase>();

  final peopleQuery = db.select(db.people)
    ..where((people) => people.id.equals(peopleId));

  final actedInQUery = db.select(db.peopleActedIn).join(
    [
      innerJoin(
        db.film,
        db.peopleActedIn.filmId.equalsExp(db.film.id),
      ),
    ],
  )..where(db.peopleActedIn.peopleId.equals(peopleId));

  final relaisatorOfQuery = db.select(db.peopleRealisatorOf).join(
    [
      innerJoin(
        db.film,
        db.peopleRealisatorOf.filmId.equalsExp(db.film.id),
      ),
    ],
  )..where(db.peopleRealisatorOf.peopleId.equals(peopleId));

  final people = await peopleQuery.getSingleOrNull();
  final actedIn = await actedInQUery.map((row) => row.readTable(db.film)).get();
  final realisatorOf =
      await relaisatorOfQuery.map((row) => row.readTable(db.film)).get();

  if (people != null) {
    return Response.json(
      body: PeopleDTO(
        people,
        actedIn,
        realisatorOf,
      ).toJson(),
    );
  }

  return notFound;
}
