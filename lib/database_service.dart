import 'package:mysql1/mysql1.dart';

class DatabaseService {
  static Future<MySqlConnection> connect() async {
    final settings = ConnectionSettings(
      host: 'localhost',
      port: 3306,
      user: 'root',  // Change if using another MySQL user
      password: '7664',  // Your MySQL password
      db: 'ventflow',
    );
    return await MySqlConnection.connect(settings);
  }
}
Future<List<Map<String, dynamic>>> getEvents() async {
  final conn = await DatabaseService.connect();
  final results = await conn.query('SELECT * FROM events');

  return results.map((row) {
    return {
      'id': row[0],
      'name': row[1],
      'date': row[2].toString(),
      'location': row[3],
      'description': row[4],
    };
  }).toList();
}
