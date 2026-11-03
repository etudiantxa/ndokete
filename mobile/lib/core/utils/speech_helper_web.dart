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
        final results = event.results;
        if (results != null) {
          for (var i = 0; i < results.length; i++) {
            final res = results[i];
            if (res != null) {
              final alt = res.item(0);
              if (alt != null && alt.transcript != null && alt.transcript!.isNotEmpty) {
                fullText += (fullText.isEmpty ? '' : ' ') + alt.transcript!;
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
