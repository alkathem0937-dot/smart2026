import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  
  bool _isListening = false;
  String _lastWords = '';

  bool get isListening => _isListening;
  String get lastWords => _lastWords;

  Future<void> init() async {
    await _tts.setLanguage('ar-SA');
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5);
  }

  Future<bool> toggleListening({required Function(String) onResult}) async {
    if (!_isListening) {
      var status = await Permission.microphone.request();
      if (status.isDenied) return false;

      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
        onError: (errorNotification) => debugPrint('STT Error: $errorNotification'),
      );

      if (available) {
        _isListening = true;
        _speech.listen(
          onResult: (result) {
            _lastWords = result.recognizedWords;
            onResult(_lastWords);
          },
          localeId: 'ar_SA',
        );
      }
      return available;
    } else {
      _isListening = false;
      await _speech.stop();
      return true;
    }
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }
}
