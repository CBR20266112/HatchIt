import 'dart:async';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final mascotAssetManagerProvider = Provider<MascotAssetManager>((ref) {
  return MascotAssetManager.instance;
});

/// 16종 마스코트 에셋의 On-Demand 다운로드 및 로컬 캐싱 관리자
class MascotAssetManager {
  static final MascotAssetManager instance = MascotAssetManager._();
  MascotAssetManager._();

  static const String releaseBaseUrl =
      'https://github.com/CBR20266112/HatchIt/releases/download/v1.0.0-assets';

  static const String fallbackAssetPath = 'assets/images/mascots/1/idle.png';
  static const String fallbackEggAssetPath = 'assets/images/eggs/egg_0.png';

  /// 특정 종(speciesId)의 로컬 저장 디렉토리 반환
  Future<Directory> getSpeciesDirectory(int speciesId) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDocDir.path, 'mascots', speciesId.toString()));
    return dir;
  }

  /// 해당 동물의 에셋(40장)이 다운로드되어 존재하는지 검사
  Future<bool> isSpeciesDownloaded(int speciesId) async {
    try {
      final dir = await getSpeciesDirectory(speciesId);
      if (!await dir.exists()) {
        return false;
      }
      final files = await dir.list().toList();
      final pngCount = files.where((e) => e is File && e.path.toLowerCase().endsWith('.png')).length;
      // 40종 중 기본 필수 에셋들이 충족되었는지 검사 (38개 이상이면 온전한 것으로 판단)
      return pngCount >= 38;
    } catch (e) {
      debugPrint('[MascotAssetManager] isSpeciesDownloaded error: $e');
      return false;
    }
  }

  /// 로컬 파일 객체 조회 (존재하지 않으면 null)
  Future<File?> getLocalImageFile(int speciesId, String filename) async {
    try {
      final dir = await getSpeciesDirectory(speciesId);
      final file = File(p.join(dir.path, filename));
      if (await file.exists()) {
        return file;
      }
    } catch (e) {
      debugPrint('[MascotAssetManager] getLocalImageFile error: $e');
    }
    return null;
  }

  /// 로컬 다운로드 폴더에 있으면 해당 File 경로 반환,
  /// 아직 다운로드 전이면 기본 알 또는 폴백 에셋 경로 반환
  Future<String> getMascotImagePath(int speciesId, String filename) async {
    final localFile = await getLocalImageFile(speciesId, filename);
    if (localFile != null) {
      return localFile.path;
    }
    return fallbackAssetPath;
  }

  /// GitHub Releases에서 동물별 압축팩(mascot_{speciesId}.zip)을 다운로드하고 로컬에 압축 해제
  Future<void> downloadMascotPack(
    int speciesId, {
    void Function(double progress)? onProgress,
  }) async {
    final url = '$releaseBaseUrl/mascot_$speciesId.zip';
    debugPrint('[MascotAssetManager] Downloading mascot pack from: $url');

    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw HttpException(
          'Failed to download mascot pack (HTTP ${response.statusCode}) from $url',
        );
      }

      final contentLength = response.contentLength ?? 0;
      final bytes = <int>[];
      int receivedBytes = 0;

      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
        receivedBytes += chunk.length;
        if (contentLength > 0 && onProgress != null) {
          final progress = (receivedBytes / contentLength).clamp(0.0, 1.0);
          onProgress(progress);
        }
      }

      onProgress?.call(0.95); // 압축 해제 직전 상태

      // 압축 해제 수행
      final archive = ZipDecoder().decodeBytes(bytes);
      final targetDir = await getSpeciesDirectory(speciesId);
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      for (final file in archive) {
        if (file.isFile) {
          final cleanFilename = p.basename(file.name);
          final outFile = File(p.join(targetDir.path, cleanFilename));
          await outFile.writeAsBytes(file.content as List<int>);
        }
      }

      onProgress?.call(1.0);
      debugPrint('[MascotAssetManager] Successfully installed mascot pack: $speciesId');
    } finally {
      client.close();
    }
  }

  /// 다운로드된 에셋 삭제 (캐시 정리용)
  Future<void> deleteMascotPack(int speciesId) async {
    try {
      final dir = await getSpeciesDirectory(speciesId);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('[MascotAssetManager] deleteMascotPack error: $e');
    }
  }
}
