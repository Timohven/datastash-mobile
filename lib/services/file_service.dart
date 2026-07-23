// lib/services/file_service.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'auth_service.dart';
import 'api_config.dart';

class FileService {

	/*
	static String getThumbnailUrl(String serverFilePath) {
		return '$API_URL/notes/thumbnails/$serverFilePath';
	}
	*/	
	/*
	static String getThumbnailUrl(String serverFilePath) {
		// Нормализуем слеши
		final normalized = serverFilePath.replaceAll(r'\', '/');
		
		// Берём только часть начиная с uploads/
		final uploadsIndex = normalized.indexOf('uploads/');
		final relativePath = uploadsIndex != -1
				? normalized.substring(uploadsIndex)
				: normalized;

		return '$API_URL/notes/thumbnails/$relativePath';
	}
	*/
	/*
	static String getThumbnailUrl(String serverFilePath) {
		final normalized = serverFilePath.replaceAll(r'\', '/');
		final filename = normalized.split('/').last; // только имя файла
		return '$API_URL/notes/thumbnails/$filename';
	}
	*/
	static String getThumbnailUrl(String serverFilePath) {
		final normalized = serverFilePath.replaceAll(r'\', '/');
		final stem = normalized.split('/').last.split('.').first; // имя без расширения
		return '$API_URL/notes/thumbnails/$stem.jpg'; // всегда .jpg
	}
	
	static Future<Directory> getDownloadDir() async {
    // Запрашиваем разрешение если ещё не дано
    if (await Permission.manageExternalStorage.isDenied) {
      await Permission.manageExternalStorage.request();
    }

    final dir = Directory('/storage/emulated/0/Download/DataStash');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<void> downloadAndOpen({
    required String serverFilePath,
    required String filename,
    void Function(int received, int total)? onProgress,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final downloadDir = await getDownloadDir();
    final localPath = p.join(downloadDir.path, filename);
    final localFile = File(localPath);

    // Если уже скачан — сразу открываем
    if (await localFile.exists()) {
      await OpenFilex.open(localPath);
      return;
    }

    // Скачиваем с сервера
    final dio = Dio();
    await dio.download(
      '$API_URL/notes/files/$serverFilePath',
      localPath,
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
      onReceiveProgress: onProgress,
    );

    // Открываем нативным приложением
    await OpenFilex.open(localPath);
  }
}
/*
class FileService {
  // Папка для всех скачанных файлов — как у Telegram
	static Future<Directory> getDownloadDir() async {
		// Проверяем статус разрешения
		if (!await Permission.manageExternalStorage.isGranted) {
			final status = await Permission.manageExternalStorage.request();
			
			if (!status.isGranted) {
				// Если не дали — открываем настройки приложения
				await openAppSettings();
				throw Exception('Нет разрешения на запись в хранилище');
			}
		}

		final dir = Directory('/storage/emulated/0/Download/DataStash');
		if (!await dir.exists()) await dir.create(recursive: true);
		return dir;
	}
/* 
 static Future<Directory> getDownloadDir() async {
    final base = await getExternalStorageDirectory(); // Android/data/com.datastash/files
    final dir = Directory(p.join(base!.path, 'DataStash'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }
*/

  // Скачать файл и открыть его
  static Future<void> downloadAndOpen({
    required String serverFilePath,  // путь как в БД: uploads/photo/IMG_001.jpg
    required String filename,         // имя файла для сохранения
    void Function(int received, int total)? onProgress,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final downloadDir = await getDownloadDir();
    final localPath = p.join(downloadDir.path, filename);
    final localFile = File(localPath);
		
print('SAVE TO: $localPath');  // ← покажет куда сохраняется

    // Если файл уже скачан — сразу открываем
    if (await localFile.exists()) {
      await OpenFilex.open(localPath);
      return;
    }

    // Скачиваем
    final dio = Dio();
    await dio.download(
      '$API_URL/notes/files/$serverFilePath',
      localPath,
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
      onReceiveProgress: onProgress,
    );

    // Открываем нативным приложением Android
    await OpenFilex.open(localPath);
  }
}
*/