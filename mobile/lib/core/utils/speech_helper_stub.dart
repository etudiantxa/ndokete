class SpeechHelper {
  static void listen({
    required void Function(String text) onResult,
    required void Function(bool isListening) onStatus,
  }) {
    onStatus(false);
  }

  static void stop() {}
}
