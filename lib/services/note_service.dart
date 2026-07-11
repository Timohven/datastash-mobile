// lib/services/note_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';
import 'api_config.dart';
import '../models/note.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class NoteService {
  static Future<bool> uploadFile({
	  required String token,
	  required String filePath,
	}) async {
	  try {
		final file = File(filePath);
		final mimeType = lookupMimeType(filePath) ?? 'application/octet-stream';
		final mimeParts = mimeType.split('/');

		final request = http.MultipartRequest(
		  'POST',
		  Uri.parse('$API_URL/notes/upload'),
		);

		request.headers['Authorization'] = 'Bearer $token';

		request.files.add(await http.MultipartFile.fromPath(
		  'file',
		  filePath,
		  contentType: MediaType(mimeParts[0], mimeParts[1]),
		));

		final response = await request.send();
		return response.statusCode == 201;
	  } catch (e) {
		return false;
	  }
	}
	 
 static Future<bool> createNote({
    required String token,
    required String text,
    String noteType = 'text',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$API_URL/notes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'note_type': noteType,
          'note_text': text,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
  
	static Future<List<Note>?> getNotes({required String token}) async {
	  try {
		final response = await http.get(
		  Uri.parse('$API_URL/notes'),
		  headers: {'Authorization': 'Bearer $token'},
		);

		if (response.statusCode == 200) {
		  final List<dynamic> data = jsonDecode(response.body);
		  return data.map((json) => Note.fromJson(json)).toList();
		}
		return null; // 401 или другая ошибка
	  } catch (e) {
		return null;
	  }
	}
	
	static Future<bool> updateNote({
	  required String token,
	  required int noteId,
	  required String noteType,
	  required String text,
	}) async {
	  try {
		final response = await http.put(
		  Uri.parse('$API_URL/notes/$noteId'),
		  headers: {
			'Content-Type': 'application/json',
			'Authorization': 'Bearer $token',
		  },
		  body: jsonEncode({
			'note_type': noteType,
			'note_text': text,
		  }),
		);
		return response.statusCode == 200;
	  } catch (e) {
		return false;
	  }
	}
}