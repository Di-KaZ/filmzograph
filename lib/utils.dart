import 'package:dart_frog/dart_frog.dart';

final notFound = Future.sync(() => Response.json(statusCode: 404));

final notImplemented = Future.sync(() => Response.json(statusCode: 501));
