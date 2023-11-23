import 'package:dart_frog/dart_frog.dart';
import 'package:drift/drift.dart';
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
  final peopleJson = await context.request.json();

  late PeopleCompanion people;

  if (peopleJson
      case {
        'name': final String name,
        'firstName': final String firstName,
        'birthDate': final String birthDate,
        'actedIn': final List<dynamic>? actedIn,
        'realisatorOf': final List<dynamic>? realisatorOf,
      }) {
    final date = DateTime.tryParse(birthDate);
    if (date == null) {
      return Response.json(
        statusCode: 400,
        body: {'message': 'malformed json'},
      );
    }
    people = PeopleCompanion.insert(
      name: name,
      firstName: firstName,
      birthDate: date,
    );

    final db = context.read<AppDatabase>();

    final transactionInsertPeople = await db.transaction(
      () async {
        final insertedPeople =
            await db.into(db.people).insertReturningOrNull(people);

        if (actedIn != null) {
          for (final acted in actedIn) {
            await db.into(db.peopleActedIn).insert(
                  PeopleActedInCompanion.insert(
                    peopleId: insertedPeople!.id,
                    filmId: acted as int,
                  ),
                );
          }

          if (realisatorOf != null) {
            for (final realised in realisatorOf) {
              await db.into(db.peopleRealisatorOf).insert(
                    PeopleRealisatorOfCompanion.insert(
                      peopleId: insertedPeople!.id,
                      filmId: realised as int,
                    ),
                  );
            }
          }

          return insertedPeople;
        }
      },
    );

    if (transactionInsertPeople != null) {
      return Response.json(body: transactionInsertPeople.toJson());
    }

    return Response.json(
      statusCode: 400,
      body: {'message': 'malformed json'},
    );
  }

  return Response.json(statusCode: 500);
}
