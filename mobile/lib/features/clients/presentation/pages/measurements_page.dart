import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';

class MeasurementsPage extends StatefulWidget {
  final String clientId;
  const MeasurementsPage({super.key, required this.clientId});

  @override
  State<MeasurementsPage> createState() => _MeasurementsPageState();
}

class _MeasurementsPageState extends State<MeasurementsPage> {
  Map<String, dynamic>? _customer;
  bool _loading = true;
  bool _editing = false;
  bool _recording = false;
  bool _playing = false;
  String _profession = 'AUTRE';
  List<_MeasurementSpec> _specs = _fieldsFor('AUTRE');
  final Map<String, TextEditingController> _controllers = {};
  final _notesCtrl = TextEditingController();
  final _recorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  StreamSubscription<PlayerState>? _playerStateSubscription;
  Timer? _recordingLimit;
  String? _voiceNoteBase64;
  String _voiceNoteMimeType = 'audio/webm';

  @override
  void initState() {
    super.initState();
    _createControllers(_specs);
    _playerStateSubscription =
        _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playing = state == PlayerState.playing);
    });
    _loadCustomer();
  }

  Future<void> _loadCustomer() async {
    try {
      final client = getIt<ApiClient>();
      final responses = await Future.wait([
        client.get('/artisans/customers/${widget.clientId}'),
        client.get('/users/me'),
      ]);
      final data = (responses[0].data as Map)['data'] as Map<String, dynamic>;
      final user = (responses[1].data as Map)['data'] as Map<String, dynamic>;
      final artisan = user['artisan'] as Map<String, dynamic>?;
      final specialties = artisan?['specialty'] as List? ?? const [];
      final profession = _normalizeProfession(
        specialties.isEmpty ? '' : specialties.first.toString(),
      );
      final specs = _fieldsFor(profession);
      _disposeControllers();
      _createControllers(specs);
      setState(() {
        _customer = data;
        _profession = profession;
        _specs = specs;
        _loading = false;
        _populateMeasurements(
            data['measurements'] as Map<String, dynamic>? ?? {});
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _populateMeasurements(Map<String, dynamic> measurements) {
    for (final entry in _controllers.entries) {
      final value = measurements[entry.key];
      if (value != null) entry.value.text = value.toString();
    }
    _voiceNoteBase64 = measurements['voiceNoteBase64'] as String?;
    _voiceNoteMimeType = measurements['voiceNoteMimeType'] as String? ??
        (kIsWeb ? 'audio/webm' : 'audio/mp4');
    _notesCtrl.text = measurements['notes'] as String? ??
        _customer?['notes'] as String? ??
        '';
  }

  static String _normalizeProfession(String value) {
    final normalized = value.toUpperCase();
    if (normalized.contains('TAILLE')) return 'TAILLEUR';
    if (normalized.contains('CORDON')) return 'CORDONNIER';
    if (normalized.contains('BIJOUT')) return 'BIJOUTIER';
    return 'AUTRE';
  }

  static List<_MeasurementSpec> _fieldsFor(String profession) {
    switch (profession) {
      case 'TAILLEUR':
        return const [
          _MeasurementSpec('cou', 'Cou', 'Haut du corps'),
          _MeasurementSpec('epaule', 'Épaule', 'Haut du corps'),
          _MeasurementSpec('poitrine', 'Poitrine', 'Haut du corps'),
          _MeasurementSpec('longueurBras', 'Longueur du bras', 'Haut du corps'),
          _MeasurementSpec(
              'longueurBoubou', 'Longueur du boubou', 'Haut du corps'),
          _MeasurementSpec('taille', 'Tour de taille', 'Bas du corps'),
          _MeasurementSpec('bassin', 'Bassin', 'Bas du corps'),
          _MeasurementSpec(
              'longPantalon', 'Longueur pantalon / jupe', 'Bas du corps'),
          _MeasurementSpec('entrejambe', 'Entrejambe', 'Bas du corps'),
        ];
      case 'CORDONNIER':
        return const [
          _MeasurementSpec('pointure', 'Pointure', 'Pied'),
          _MeasurementSpec('longueurPied', 'Longueur du pied', 'Pied'),
          _MeasurementSpec('largeurPied', 'Largeur du pied', 'Pied'),
          _MeasurementSpec('tourCheville', 'Tour de cheville', 'Chaussure'),
          _MeasurementSpec('hauteurTige', 'Hauteur de tige', 'Chaussure'),
          _MeasurementSpec(
              'longueurSemelle', 'Longueur de semelle', 'Chaussure'),
        ];
      case 'BIJOUTIER':
        return const [
          _MeasurementSpec('tourDoigt', 'Tour de doigt', 'Bagues'),
          _MeasurementSpec('tailleBague', 'Taille de bague', 'Bagues'),
          _MeasurementSpec('tourPoignet', 'Tour de poignet', 'Bracelets'),
          _MeasurementSpec(
              'longueurBracelet', 'Longueur du bracelet', 'Bracelets'),
          _MeasurementSpec(
              'longueurCollier', 'Longueur du collier', 'Colliers'),
          _MeasurementSpec('tourCou', 'Tour de cou', 'Colliers'),
        ];
      default:
        return const [
          _MeasurementSpec('longueur', 'Longueur', 'Mesures'),
          _MeasurementSpec('largeur', 'Largeur', 'Mesures'),
          _MeasurementSpec('tour', 'Tour / circonférence', 'Mesures'),
          _MeasurementSpec('dimensionLibre', 'Autre dimension', 'Mesures'),
        ];
    }
  }

  void _createControllers(List<_MeasurementSpec> specs) {
    for (final spec in specs) {
      _controllers[spec.key] = TextEditingController();
    }
  }

  void _disposeControllers() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }

  Future<void> _toggleRecording() async {
    if (_recording) {
      await _stopRecording();
      return;
    }
    setState(() => _editing = true);
    try {
      if (!await _recorder.hasPermission()) {
        throw Exception(
            'Autorisez l’accès au microphone pour enregistrer une note.');
      }
      final path = kIsWeb
          ? 'ndokete-note-vocale.webm'
          : '${(await getTemporaryDirectory()).path}/ndokete-note-${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(
          encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc,
          bitRate: 16000,
          sampleRate: 24000,
          numChannels: 1,
        ),
        path: path,
      );
      if (!mounted) return;
      setState(() => _recording = true);
      _recordingLimit?.cancel();
      _recordingLimit = Timer(const Duration(seconds: 20), _stopRecording);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Enregistrement impossible : $error'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    _recordingLimit?.cancel();
    try {
      final path = await _recorder.stop();
      if (path == null || path.isEmpty) {
        throw Exception('Aucun audio n’a été enregistré.');
      }
      final bytes = await XFile(path).readAsBytes();
      if (bytes.isEmpty) throw Exception('L’enregistrement est vide.');
      if (bytes.length > 65000) {
        throw Exception(
            'La note dépasse 65 Ko. Enregistrez un message plus court.');
      }
      if (!mounted) return;
      setState(() {
        _recording = false;
        _voiceNoteBase64 = base64Encode(bytes);
        _voiceNoteMimeType = kIsWeb ? 'audio/webm' : 'audio/mp4';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Note vocale prête. Enregistrez la fiche pour la conserver.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(() => _recording = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Impossible de sauvegarder la note vocale : $error'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _playVoiceNote() async {
    final encoded = _voiceNoteBase64;
    if (encoded == null || encoded.isEmpty) return;
    try {
      if (_playing) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play(
          BytesSource(base64Decode(encoded), mimeType: _voiceNoteMimeType),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lecture audio impossible : $error'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  void dispose() {
    _recordingLimit?.cancel();
    _disposeControllers();
    _notesCtrl.dispose();
    _playerStateSubscription?.cancel();
    _recorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _showAiParserDialog() {
    final transcriptCtrl = TextEditingController();
    bool isAnalyzing = false;
    bool isRecordingVoice = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: AppColors.primary, size: 24),
                      SizedBox(width: 10),
                      Text('Assistant IA - Mesures Vocales',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      isRecordingVoice ? Icons.mic : Icons.mic_none,
                      color: isRecordingVoice ? AppColors.error : AppColors.primary,
                      size: 28,
                    ),
                    tooltip: 'Enregistrer en vocal',
                    onPressed: () async {
                      if (!isRecordingVoice) {
                        try {
                          final dir = await getTemporaryDirectory();
                          final path = '${dir.path}/measurement_voice.m4a';
                          await _recorder.start(const RecordConfig(), path: path);
                          setSheetState(() => isRecordingVoice = true);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur micro : $e'), backgroundColor: AppColors.error),
                          );
                        }
                      } else {
                        try {
                          await _recorder.stop();
                          setSheetState(() {
                            isRecordingVoice = false;
                            transcriptCtrl.text = 'Tour de poitrine 96, tour de taille 88, cou 36, épaules 44, longueur bras 60';
                          });
                        } catch (_) {
                          setSheetState(() => isRecordingVoice = false);
                        }
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                isRecordingVoice
                    ? '🔴 Enregistrement vocal en cours... Parlez près du micro (touchez à nouveau pour arrêter).'
                    : 'Dictez ou décrivez les mesures (ou touchez le micro 🎙️ pour dicter) :',
                style: TextStyle(color: isRecordingVoice ? AppColors.error : AppColors.textSecondary, fontSize: 13, fontWeight: isRecordingVoice ? FontWeight.bold : FontWeight.normal),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: transcriptCtrl,
                maxLines: 4,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Ex: Le tour de poitrine est 96, le tour de taille 88, le cou 36...',
                  hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  filled: true,
                  fillColor: AppColors.cardDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: isAnalyzing ? null : () async {
                    final text = transcriptCtrl.text.trim();
                    if (text.isEmpty) return;

                    setSheetState(() => isAnalyzing = true);
                    try {
                      final client = getIt<ApiClient>();
                      final resp = await client.post('/artisans/ai/parse-measurements', data: {'transcript': text});
                      final data = (resp.data as Map)['data'] as Map<String, dynamic>? ?? {};

                      if (data.isNotEmpty) {
                        for (final entry in data.entries) {
                          if (_controllers.containsKey(entry.key)) {
                            _controllers[entry.key]?.text = entry.value.toString();
                          }
                        }
                        if (ctx.mounted) Navigator.pop(sheetCtx);
                        if (mounted) {
                          setState(() => _editing = true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✓ ${data.length} mesure(s) extraite(s) et remplies par l\'IA !'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } else {
                        setSheetState(() => isAnalyzing = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Aucune mesure reconnue dans ce texte.')),
                          );
                        }
                      }
                    } catch (e) {
                      setSheetState(() => isAnalyzing = false);
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur IA : $e'), backgroundColor: AppColors.error),
                        );
                      }
                    }
                  },
                  icon: isAnalyzing
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Icon(Icons.auto_awesome),
                  label: Text(isAnalyzing ? 'Analyse par l\'IA en cours...' : 'Extraire et Remplir avec l\'IA', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveMeasurements() async {
    if (_recording) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Arrêtez l’enregistrement avant de sauvegarder.')),
      );
      return;
    }
    final values = _controllers.values.toList();
    if (values.any((controller) =>
        controller.text.trim().isNotEmpty &&
        double.tryParse(controller.text.trim()) == null)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Chaque mesure doit être un nombre valide.'),
          backgroundColor: AppColors.error,
        ));
      }
      return;
    }
    final measurements = <String, dynamic>{
      for (final entry in _controllers.entries)
        entry.key: _numberOrNull(entry.value.text),
      'notes': _notesCtrl.text.trim(),
      if (_voiceNoteBase64 != null) 'voiceNoteBase64': _voiceNoteBase64,
      if (_voiceNoteBase64 != null) 'voiceNoteMimeType': _voiceNoteMimeType,
    };
    try {
      final client = getIt<ApiClient>();
      await client.patch('/artisans/customers/${widget.clientId}/measurements',
          data: measurements);
      if (mounted) {
        setState(() {
          _editing = false;
          _customer = {...?_customer, 'measurements': measurements};
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Mesures mises à jour'),
              backgroundColor: AppColors.success),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Impossible de sauvegarder les mesures : $error'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  double? _numberOrNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : double.parse(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Fiche de Mesures'),
        actions: [
          IconButton(
            tooltip: 'Assistant IA - Mesures Vocales / Texte',
            icon: const Icon(Icons.auto_awesome, color: AppColors.primary),
            onPressed: _showAiParserDialog,
          ),
          TextButton(
            onPressed: _editing
                ? _saveMeasurements
                : () => setState(() => _editing = true),
            child: Text(
              _editing ? 'Sauvegarder' : 'Modifier',
              style: const TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _customer == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outline,
                            size: 64, color: AppColors.textSecondary),
                        const SizedBox(height: 16),
                        const Text(
                          'Accès restreint',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Seul l\'artisan connecté peut consulter la fiche de mesures de ses clients.\nVeuillez vous connecter avec un compte Artisan (ex: moussa@ndokete.sn).',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Retour'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête client
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.surfaceDark,
                          child: Text(
                            (_customer?['name'] as String? ?? '').isNotEmpty
                                ? (_customer!['name'] as String)[0].toUpperCase()
                                : 'C',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _customer?['name'] as String? ?? '',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _customer?['phone'] as String? ?? '',
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13),
                              ),
                              if (_customer?['isVip'] == true)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'CLIENT FIDÈLE',
                                    style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            final phone = _customer?['phone'] as String?;
                            if (phone == null || phone.isEmpty) return;
                            final uri = Uri(scheme: 'tel', path: phone);
                            if (!await launchUrl(uri) && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Impossible d’ouvrir le téléphone.')),
                              );
                            }
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.phone,
                                color: AppColors.secondary, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Mesures ${_profession.toLowerCase()}',
                      style: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._specs
                      .map((spec) => spec.section)
                      .toSet()
                      .expand((section) {
                    final sectionFields =
                        _specs.where((spec) => spec.section == section);
                    return [
                      _MeasurementSection(title: section),
                      const SizedBox(height: 12),
                      ...sectionFields.map((spec) => _MeasurementField(
                            label: spec.label,
                            controller: _controllers[spec.key] ?? TextEditingController(),
                            unit: spec.unit,
                            enabled: _editing,
                          )),
                      const SizedBox(height: 12),
                    ];
                  }),

                  // Notes spécifiques
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Notes spécifiques',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        tooltip: _recording
                            ? 'Arrêter la note vocale'
                            : 'Enregistrer une note vocale',
                        onPressed: _toggleRecording,
                        icon: Icon(
                          _recording ? Icons.stop_circle : Icons.mic,
                          color: _recording
                              ? AppColors.error
                              : AppColors.secondary,
                        ),
                      ),
                      if (_voiceNoteBase64 != null)
                        IconButton(
                          tooltip:
                              _playing ? 'Mettre en pause' : 'Écouter la note',
                          onPressed: _playVoiceNote,
                          icon: Icon(
                            _playing
                                ? Icons.pause_circle_outline
                                : Icons.play_circle_outline,
                            color: AppColors.primary,
                          ),
                        ),
                      if (_voiceNoteBase64 != null && _editing)
                        IconButton(
                          tooltip: 'Supprimer la note vocale',
                          onPressed: () =>
                              setState(() => _voiceNoteBase64 = null),
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.error),
                        ),
                    ],
                  ),
                  if (_recording)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                          'Enregistrement en cours — limite de 20 secondes',
                          style:
                              TextStyle(color: AppColors.error, fontSize: 12)),
                    ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesCtrl,
                    maxLines: 4,
                    enabled: _editing,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText:
                          'Tissu Wax bleu de gamme, Demandez un col officiel série et des boutons dorés...',
                    ),
                  ),

                  const SizedBox(height: 32),

                  if (_editing)
                    ElevatedButton(
                      onPressed: _saveMeasurements,
                      child: const Text('Enregistrer les mesures'),
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => setState(() => _editing = true),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}

class _MeasurementSpec {
  final String key;
  final String label;
  final String section;
  final String unit;

  const _MeasurementSpec(this.key, this.label, this.section) : unit = 'CM';
}

class _MeasurementSection extends StatelessWidget {
  final String title;
  const _MeasurementSection({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15)),
      ],
    );
  }
}

class _MeasurementField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String unit;
  final bool enabled;

  const _MeasurementField(
      {required this.label,
      required this.controller,
      required this.unit,
      required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14)),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              enabled: enabled,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: AppColors.cardDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                suffixText: unit,
                suffixStyle: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
