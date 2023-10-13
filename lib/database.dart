import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
part 'database.g.dart';

/// Represent a film entity in the database
class Film extends Table {
  /// The id of the film
  IntColumn get id => integer().autoIncrement()();

  /// The name of the film
  TextColumn get name => text().withLength(max: 128)();

  /// The long description of this film
  TextColumn get description => text().withLength(max: 2048)();

  /// The date of release for this film
  DateTimeColumn get releaseDate => dateTime()();
}

/// Represent a film entity in the database
class People extends Table {
  /// The id of the people
  IntColumn get id => integer().autoIncrement()();

  /// The name of the people
  TextColumn get name => text().withLength(max: 128)();

  /// The firstname of the people
  TextColumn get firstName => text().withLength(max: 128)();

  /// The date of birth of this people
  DateTimeColumn get birthDate => dateTime()();
}

/// Many to many table representing the fact that [peopleId] acted in [filmId]
class PeopleActedIn extends Table {
  /// The people who acted in the film with [filmId]
  IntColumn get peopleId => integer().references(People, #id)();

  /// The film who people with [peopleId] acted in
  IntColumn get filmId => integer().references(Film, #id)();
}

/// Many to many table representing the fact that [peopleId] realisated [filmId]
class PeopleRealisatorOf extends Table {
  /// The people who realised the film with [filmId]
  IntColumn get peopleId => integer().references(People, #id)();

  /// The film who people with [peopleId] realised
  IntColumn get filmId => integer().references(Film, #id)();
}

@DriftDatabase(
  tables: [
    Film,
    People,
    PeopleActedIn,
    PeopleRealisatorOf,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  // the LazyDatabase util lets us find the right location for the file async.
  return LazyDatabase(() async {
    // put the database file, called db.sqlite here, into the documents folder
    // for your app.
    final file = File('db.sqlite');
    return NativeDatabase.createInBackground(file);
  });
}
