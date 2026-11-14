// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js' as js;

class SpeechHelper {
  static dynamic _recognition;
  static bool _isManuallyStopped = false;

  static void listen({
    required void Function(String text) onResult,
    required void Function(bool isListening) onStatus,
  }) {
    try {
      _isManuallyStopped = false;
      if (_recognition != null) {
        _recognition.callMethod('stop', []);
      }

      final speechRecClass = js.context['SpeechRecognition'] ?? js.context['webkitSpeechRecognition'];
      if (speechRecClass == null) {
        onStatus(false);
        return;
      }

      _recognition = js.JsObject(speechRecClass, []);
      _recognition['lang'] = 'fr-FR';
      _recognition['continuous'] = true;
      _recognition['interimResults'] = true;

      _recognition.callMethod('addEventListener', [
        'result',
        (html.Event event) {
          final jsEvent = js.JsObject.fromBrowserObject(event);
          final results = jsEvent['results'];
          String fullText = '';
          if (results != null) {
            for (var i = 0; i < results['length']; i++) {
              final res = results.callMethod('item', [i]);
              final alt = res.callMethod('item', [0]);
              final transcript = alt['transcript'];
              if (transcript != null && transcript.toString().isNotEmpty) {
                fullText += (fullText.isEmpty ? '' : ' ') + transcript.toString();
              }
            }
          }
          if (fullText.isNotEmpty) {
            onResult(fullText);
          }
        }
      ]);

      _recognition.callMethod('addEventListener', [
        'end',
        (html.Event event) {
          if (!_isManuallyStopped) {
            try {
              _recognition.callMethod('start', []);
              return;
            } catch (_) {}
          }
          onStatus(false);
        }
      ]);

      _recognition.callMethod('addEventListener', [
        'error',
        (html.Event event) {
          if (!_isManuallyStopped) {
            try {
              _recognition.callMethod('start', []);
              return;
            } catch (_) {}
          }
          onStatus(false);
        }
      ]);

      _recognition.callMethod('start', []);
      onStatus(true);
    } catch (_) {
      onStatus(false);
    }
  }

  static void stop() {
    try {
      _isManuallyStopped = true;
      _recognition?.callMethod('stop', []);
      _recognition = null;
    } catch (_) {}
  }
}
