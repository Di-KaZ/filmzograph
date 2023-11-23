import 'package:dart_frog/dart_frog.dart';
import 'package:filmzy/database.dart';

AppDatabase? _db;

Handler middleware(Handler handler) {
  return handler.use(provider<AppDatabase>((context) => _db ??= AppDatabase()));
}
