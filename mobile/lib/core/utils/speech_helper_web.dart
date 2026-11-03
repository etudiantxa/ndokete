// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class SpeechHelper {
  static html.SpeechRecognition? _recognition;

  static void listen({
    required void Function(String text) onResult,
    required void Function(bool isListening) onStatus,
  }) {
    try {
      if (_recognition != null) {
        _recognition!.stop();
      }
      _recognition = html.SpeechRecognition();
      _recognition!.lang = 'fr-FR';
      _recognition!.continuous = true;
      _recognition!.interimResults = true;

      _recognition!.onResult.listen((event) {
        String fullText = '';
        if (event.results != null) {
          for (var i = 0; i < event.results!.length; i++) {
            final res = event.results![i];
            if (res != null && res.length > 0) {
              final text = res[0]?.transcript;
              if (text != null && text.isNotEmpty) {
                fullText += (fullText.isEmpty ? '' : ' ') + text;
              }
            }
          }
        }
        if (fullText.isNotEmpty) {
          onResult(fullText);
        }
      });

      _recognition!.onEnd.listen((_) {
        onStatus(false);
      });

      _recognition!.onError.listen((_) {
        onStatus(false);
      });

      _recognition!.start();
      onStatus(true);
    } catch (_) {
      onStatus(false);
    }
  }

  static void stop() {
    try {
      _recognition?.stop();
      _recognition = null;
    } catch (_) {}
  }
}
