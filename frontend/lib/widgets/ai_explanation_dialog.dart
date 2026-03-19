import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../config/app_config.dart';

// ── Section model ─────────────────────────────────────────────────────────────
class _Section {
  final IconData icon;
  final String label;
  final Color color;
  final String text;
  const _Section({
    required this.icon,
    required this.label,
    required this.color,
    required this.text,
  });
}

// ── Main dialog ───────────────────────────────────────────────────────────────
class AiExplanationDialog extends StatefulWidget {
  final String topic;
  final String explanation;

  const AiExplanationDialog({
    super.key,
    required this.topic,
    required this.explanation,
  });

  @override
  State<AiExplanationDialog> createState() => _AiExplanationDialogState();
}

class _AiExplanationDialogState extends State<AiExplanationDialog>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  bool _isLoadingAudio = false;
  String _selectedLang = 'en';
  late List<_Section> _sections;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // dart:html audio element
  html.AudioElement? _audioElement;
  String? _objectUrl;

  final _dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    headers: {'X-Session-ID': AppConfig.instance.sessionId},
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
  ));

  @override
  void initState() {
    super.initState();
    _sections = _parseSections(widget.explanation);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  List<_Section> _parseSections(String text) {
    final clean = text
        .replaceAll(
            RegExp(r'<think>[\s\S]*?</think>', caseSensitive: false), '')
        .trim();
    final paragraphs = clean
        .split(RegExp(r'\n\n+'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    final icons = [
      Icons.lightbulb_outline_rounded,
      Icons.emoji_objects_outlined,
      Icons.science_outlined,
      Icons.stars_rounded,
    ];
    final labels = [
      'Definition',
      'Real-Life Example',
      'How It Works',
      'Fun Fact'
    ];
    final colors = [
      const Color(0xFF60B4F0),
      const Color(0xFF1D9E75),
      const Color(0xFFBA68C8),
      const Color(0xFFEF9F27),
    ];

    return List.generate(paragraphs.length, (i) {
      final idx = i.clamp(0, icons.length - 1);
      return _Section(
        icon: icons[idx],
        label: labels[idx],
        color: colors[idx],
        text: paragraphs[i],
      );
    });
  }

  @override
  void dispose() {
    _stopAudio();
    _pulseController.dispose();
    super.dispose();
  }

  String get _formattedTopic => widget.topic
      .split('-')
      .map((w) =>
          w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
      .join(' ');

  void _stopAudio() {
    _audioElement?.pause();
    _audioElement = null;
    if (_objectUrl != null) {
      html.Url.revokeObjectUrl(_objectUrl!);
      _objectUrl = null;
    }
    if (mounted) {
      setState(() {
        _isPlaying = false;
        _isLoadingAudio = false;
      });
    }
  }

  Future<void> _toggleAudio() async {
    if (_isPlaying || _isLoadingAudio) {
      _stopAudio();
      return;
    }

    setState(() => _isLoadingAudio = true);

    try {
      final langCode = _selectedLang == 'te' ? 'te-IN' : 'en-IN';

      // Clean text — strip any <think> tags
      final cleanText = widget.explanation
          .replaceAll(
              RegExp(r'<think>[\s\S]*?</think>', caseSensitive: false), '')
          .trim();

      // Call backend TTS
      final response = await _dio.post<Map<String, dynamic>>(
        '/ai/tts',
        data: {'text': cleanText, 'language': langCode},
      );

      final audioBase64 = response.data?['audio_base64'] as String?;
      if (audioBase64 == null || audioBase64.isEmpty) {
        throw Exception('No audio received from server');
      }

      // Decode base64 → bytes → Blob → Object URL
      final audioBytes = base64Decode(audioBase64);
      final blob = html.Blob([audioBytes], 'audio/wav');
      _objectUrl = html.Url.createObjectUrlFromBlob(blob);

      // Create HTML audio element and play
      _audioElement = html.AudioElement(_objectUrl!);

      _audioElement!.onEnded.listen((_) {
        if (mounted) setState(() => _isPlaying = false);
        // Cleanup URL after playback
        if (_objectUrl != null) {
          html.Url.revokeObjectUrl(_objectUrl!);
          _objectUrl = null;
        }
      });

      _audioElement!.onError.listen((_) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _isLoadingAudio = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Audio playback failed'),
              backgroundColor: Color(0xFF1A1A24),
            ),
          );
        }
      });

      await _audioElement!.play();

      if (mounted) {
        setState(() {
          _isLoadingAudio = false;
          _isPlaying = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAudio = false;
          _isPlaying = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Audio error: ${e.toString()}'),
            backgroundColor: const Color(0xFF1A1A24),
          ),
        );
      }
    }
  }

  Future<void> _changeLang(String lang) async {
    if (_isPlaying || _isLoadingAudio) _stopAudio();
    setState(() => _selectedLang = lang);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 700;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isWide ? size.width * 0.07 : 12,
        vertical: 24,
      ),
      child: Container(
        width: isWide ? 860 : double.infinity,
        constraints: BoxConstraints(maxHeight: size.height * 0.92),
        decoration: BoxDecoration(
          color: const Color(0xFF12121E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF9C27B0).withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9C27B0).withValues(alpha: 0.18),
              blurRadius: 40,
              spreadRadius: 6,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              child: _buildAudioCard(),
            ),
            const SizedBox(height: 14),
            _buildDivider(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                child: _sections.length > 1
                    ? _buildSectionedContent()
                    : _buildPlainContent(),
              ),
            ),
            const SizedBox(height: 16),
            _buildGotItButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 18, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF9C27B0).withValues(alpha: 0.22),
            const Color(0xFF673AB7).withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9C27B0).withValues(alpha: 0.45),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 26),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Tutor',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3)),
                const SizedBox(height: 3),
                Text(_formattedTopic,
                    style: const TextStyle(
                        color: Color(0xFFBA68C8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(9),
              ),
              child:
                  const Icon(Icons.close, color: Colors.white60, size: 18),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.headphones_rounded,
                  color: const Color(0xFF9C27B0).withValues(alpha: 0.9),
                  size: 18),
              const SizedBox(width: 8),
              const Text('Listen in your language',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D9E75).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: const Color(0xFF1D9E75).withValues(alpha: 0.4)),
                ),
                child: const Text('Sarvam AI',
                    style: TextStyle(
                        color: Color(0xFF1D9E75),
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _langButton('en', '🇬🇧  English'),
              const SizedBox(width: 10),
              _langButton('te', '🇮🇳  Telugu'),
              const Spacer(),
              // Play / Stop button
              GestureDetector(
                onTap: _toggleAudio,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isPlaying
                          ? [
                              const Color(0xFFE53935),
                              const Color(0xFFB71C1C)
                            ]
                          : _isLoadingAudio
                              ? [
                                  const Color(0xFF444455),
                                  const Color(0xFF333344)
                                ]
                              : [
                                  const Color(0xFF9C27B0),
                                  const Color(0xFF6A1B9A)
                                ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: (_isPlaying
                                ? Colors.red
                                : const Color(0xFF9C27B0))
                            .withValues(alpha: 0.35),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isLoadingAudio)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      else
                        Icon(
                          _isPlaying
                              ? Icons.stop_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      const SizedBox(width: 7),
                      Text(
                        _isLoadingAudio
                            ? 'Loading...'
                            : _isPlaying
                                ? 'Stop'
                                : 'Listen',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isPlaying) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: const Color(0xFF9C27B0).withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedLang == 'te'
                      ? 'తెలుగులో చదువుతోంది...'
                      : 'Reading aloud in English...',
                  style: TextStyle(
                    color: const Color(0xFF9C27B0).withValues(alpha: 0.7),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _langButton(String lang, String label) {
    final isSelected = _selectedLang == lang;
    return GestureDetector(
      onTap: () => _changeLang(lang),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF9C27B0)
              : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF9C27B0)
                : Colors.white.withValues(alpha: 0.15),
            width: 1.2,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white60,
              fontSize: 13,
              fontWeight:
                  isSelected ? FontWeight.w700 : FontWeight.w400,
            )),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(children: [
        Expanded(
            child: Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.07))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('Explanation',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.25),
                  fontSize: 11,
                  letterSpacing: 1.5)),
        ),
        Expanded(
            child: Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.07))),
      ]),
    );
  }

  Widget _buildSectionedContent() {
    return Column(
        children: _sections.map((s) => _buildSectionCard(s)).toList());
  }

  Widget _buildSectionCard(_Section section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: section.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: section.color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: BoxDecoration(
              color: section.color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: section.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(section.icon,
                      color: section.color, size: 16),
                ),
                const SizedBox(width: 10),
                Text(section.label,
                    style: TextStyle(
                        color: section.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Text(
              section.text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 15,
                height: 1.8,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlainContent() {
    final clean = widget.explanation
        .replaceAll(
            RegExp(r'<think>[\s\S]*?</think>', caseSensitive: false),
            '')
        .trim();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        clean,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.88),
          fontSize: 15,
          height: 1.8,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.15,
        ),
      ),
    );
  }

  Widget _buildGotItButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF9C27B0),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: const Text('Got it!',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5)),
        ),
      ),
    );
  }
}

// ── Loading dialog ────────────────────────────────────────────────────────────
class LoadingDialog extends StatelessWidget {
  const LoadingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF12121E),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: const Color(0xFF9C27B0),
                strokeWidth: 3,
                backgroundColor:
                    const Color(0xFF9C27B0).withValues(alpha: 0.15),
              ),
            ),
            const SizedBox(height: 20),
            const Text('AI Tutor is thinking...',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Preparing a clear explanation for you',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
Future<void> showAiExplanation(
  BuildContext context,
  String topic,
  String explanation,
) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.75),
    builder: (context) =>
        AiExplanationDialog(topic: topic, explanation: explanation),
  );
}

Future<void> showLoading(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.75),
    builder: (context) => const LoadingDialog(),
  );
}