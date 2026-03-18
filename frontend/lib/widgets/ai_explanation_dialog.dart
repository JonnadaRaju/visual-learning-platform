import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

// ── Section model for structured display ─────────────────────────────────────
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
  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlaying = false;
  bool _isInitialized = false;
  String _selectedLanguage = 'en-US';
  int _currentWordIndex = -1;
  late List<String> _words;
  late List<_Section> _sections;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Telugu translation map for common physics/math terms shown in UI only
  static const Map<String, String> _teluguTopicNames = {
    'projectile-motion': 'ప్రక్షేపక చలనం',
    'waves-shm': 'తరంగాలు / SHM',
    'electric-circuits': 'విద్యుత్ వలయాలు',
    'gravitation-orbits': 'గురుత్వాకర్షణ & కక్ష్యలు',
    'newtons-laws': 'న్యూటన్ నియమాలు',
    'fluid-pressure': 'ద్రవ పీడనం',
    'linear-equations': 'రేఖీయ సమీకరణాలు',
    'geometry': 'రేఖాగణితం',
    'atomic-structure': 'పరమాణు నిర్మాణం',
    'acids-bases': 'ఆమ్లాలు & క్షారాలు',
  };

  @override
  void initState() {
    super.initState();
    _words = widget.explanation.split(RegExp(r'\s+'));
    _sections = _parseSections(widget.explanation);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initTts();
  }

  // Split explanation into paragraphs and assign icons/labels
  List<_Section> _parseSections(String text) {
    final paragraphs = text
        .split(RegExp(r'\n\n+'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    final icons = [
      Icons.lightbulb_outline_rounded,
      Icons.emoji_objects_outlined,
      Icons.science_outlined,
      Icons.public_rounded,
    ];
    final labels = ['Definition', 'Real-Life Example', 'How It Works', 'Fun Fact'];
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

  Future<void> _initTts() async {
    await _flutterTts.setLanguage(_selectedLanguage);
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      if (mounted) setState(() => _isPlaying = true);
    });
    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() { _isPlaying = false; _currentWordIndex = -1; });
    });
    _flutterTts.setCancelHandler(() {
      if (mounted) setState(() { _isPlaying = false; _currentWordIndex = -1; });
    });
    _flutterTts.setErrorHandler((_) {
      if (mounted) setState(() { _isPlaying = false; _currentWordIndex = -1; });
    });
    _flutterTts.setProgressHandler((text, start, end, word) {
      if (mounted && word.isNotEmpty) {
        final idx = _words.indexWhere(
            (w) => w.toLowerCase().startsWith(word[0].toLowerCase()));
        if (idx >= 0) setState(() => _currentWordIndex = idx);
      }
    });

    setState(() => _isInitialized = true);
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _pulseController.dispose();
    super.dispose();
  }

  String get _formattedTopic => widget.topic
      .split('-')
      .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
      .join(' ');

  String get _teluguTopic =>
      _teluguTopicNames[widget.topic] ?? _formattedTopic;

  Future<void> _playAudio() async {
    if (_isPlaying) {
      await _flutterTts.stop();
      setState(() { _isPlaying = false; _currentWordIndex = -1; });
      return;
    }
    // Ensure language is set before speaking
    await _flutterTts.stop();
    await _flutterTts.setLanguage(_selectedLanguage);
    await Future.delayed(const Duration(milliseconds: 100));
    setState(() { _isPlaying = true; _currentWordIndex = 0; });
    await _flutterTts.speak(widget.explanation);
  }

  Future<void> _changeLanguage(String langCode) async {
    if (_isPlaying) await _flutterTts.stop();
    await _flutterTts.setLanguage(langCode);
    setState(() {
      _selectedLanguage = langCode;
      _isPlaying = false;
      _currentWordIndex = -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTelugu = _selectedLanguage == 'te-IN';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 680,
          maxHeight: size.height * 0.92,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF12121E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF9C27B0).withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9C27B0).withValues(alpha: 0.15),
              blurRadius: 32,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            _buildHeader(isTelugu),
            // ── Audio card ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: _buildAudioCard(isTelugu),
            ),
            const SizedBox(height: 12),
            // ── Divider ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.07))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text('Explanation',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11, letterSpacing: 1.2)),
                ),
                Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.07))),
              ]),
            ),
            const SizedBox(height: 12),
            // ── Content ──────────────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: _sections.length > 1
                    ? _buildSectionedContent()
                    : _buildPlainContent(),
              ),
            ),
            const SizedBox(height: 16),
            // ── Got it button ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isTelugu) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF9C27B0).withValues(alpha: 0.2),
            const Color(0xFF673AB7).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          // Animated icon
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9C27B0).withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Tutor',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  )),
                const SizedBox(height: 3),
                Text(
                  isTelugu ? _teluguTopic : _formattedTopic,
                  style: TextStyle(
                    color: const Color(0xFF9C27B0).withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close, color: Colors.white54, size: 18),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioCard(bool isTelugu) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.headphones_rounded,
                color: const Color(0xFF9C27B0).withValues(alpha: 0.9), size: 18),
              const SizedBox(width: 8),
              Text('Listen in your language',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Language buttons
              _langButton('en-US', '🇬🇧  English'),
              const SizedBox(width: 8),
              _langButton('te-IN', '🇮🇳  Telugu'),
              const Spacer(),
              // Play/stop button
              GestureDetector(
                onTap: _isInitialized ? _playAudio : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isPlaying
                          ? [const Color(0xFFE53935), const Color(0xFFB71C1C)]
                          : [const Color(0xFF9C27B0), const Color(0xFF6A1B9A)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: (_isPlaying
                            ? Colors.red
                            : const Color(0xFF9C27B0))
                            .withValues(alpha: 0.35),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isPlaying ? 'Stop' : 'Listen',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
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
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: Color(0xFF9C27B0),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isTelugu ? 'తెలుగులో చదువుతోంది...' : 'Reading aloud...',
                  style: TextStyle(
                    color: const Color(0xFF9C27B0).withValues(alpha: 0.8),
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

  Widget _langButton(String code, String label) {
    final isSelected = _selectedLanguage == code;
    return GestureDetector(
      onTap: () => _changeLanguage(code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF9C27B0)
              : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF9C27B0)
                : Colors.white.withValues(alpha: 0.15),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  // Beautiful sectioned layout with icons
  Widget _buildSectionedContent() {
    return Column(
      children: _sections.asMap().entries.map((entry) {
        final idx = entry.key;
        final section = entry.value;
        return _buildSectionCard(section, idx);
      }).toList(),
    );
  }

  Widget _buildSectionCard(_Section section, int idx) {
    // Split section text into words for highlight
    final sectionWords = section.text.split(RegExp(r'\s+'));
    final globalStart = _sections
        .take(idx)
        .fold(0, (sum, s) => sum + s.text.split(RegExp(r'\s+')).length + 1);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: section.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: section.color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            decoration: BoxDecoration(
              color: section.color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: section.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(section.icon, color: section.color, size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  section.label,
                  style: TextStyle(
                    color: section.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          // Section text with word highlighting
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: RichText(
              text: TextSpan(
                children: sectionWords.asMap().entries.map((e) {
                  final globalIdx = globalStart + e.key;
                  final isHighlighted = _isPlaying &&
                      _currentWordIndex >= 0 &&
                      globalIdx >= _currentWordIndex &&
                      globalIdx <= _currentWordIndex + 4;
                  return TextSpan(
                    text: '${e.value} ',
                    style: TextStyle(
                      color: isHighlighted
                          ? const Color(0xFFFFD700)
                          : Colors.white.withValues(alpha: 0.88),
                      fontSize: 15,
                      height: 1.75,
                      fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w400,
                      letterSpacing: 0.1,
                      backgroundColor: isHighlighted
                          ? section.color.withValues(alpha: 0.25)
                          : Colors.transparent,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Fallback plain content (single paragraph)
  Widget _buildPlainContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: RichText(
        text: TextSpan(
          children: _words.asMap().entries.map((e) {
            final isHighlighted = _isPlaying &&
                _currentWordIndex >= 0 &&
                e.key >= _currentWordIndex &&
                e.key <= _currentWordIndex + 4;
            return TextSpan(
              text: '${e.value} ',
              style: TextStyle(
                color: isHighlighted
                    ? const Color(0xFFFFD700)
                    : Colors.white.withValues(alpha: 0.88),
                fontSize: 15,
                height: 1.75,
                fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w400,
                backgroundColor: isHighlighted
                    ? const Color(0xFF9C27B0).withValues(alpha: 0.25)
                    : Colors.transparent,
              ),
            );
          }).toList(),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                backgroundColor: const Color(0xFF9C27B0).withValues(alpha: 0.15),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'AI Tutor is thinking...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Preparing a clear explanation for you',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helper functions ──────────────────────────────────────────────────────────
Future<void> showAiExplanation(
  BuildContext context,
  String topic,
  String explanation,
) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (context) => AiExplanationDialog(
      topic: topic,
      explanation: explanation,
    ),
  );
}

Future<void> showLoading(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (context) => const LoadingDialog(),
  );
}