import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

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
  String _selectedLang = 'en';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final Map<String, Map<String, String>> _languages = {
    'en': {
      'name': 'English',
      'tts': 'en-US',
      'listenText': 'Listening in English...',
      'buttonText': 'Listen',
    },
    'te': {
      'name': 'Telugu',
      'tts': 'te-IN',
      'listenText': 'Listening in Telugu...',
      'buttonText': 'Listen',
    },
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      if (mounted) setState(() => _isPlaying = true);
    });

    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isPlaying = false);
    });

    _flutterTts.setCancelHandler(() {
      if (mounted) setState(() => _isPlaying = false);
    });

    _flutterTts.setErrorHandler((msg) {
      if (mounted) setState(() => _isPlaying = false);
    });

    if (mounted) setState(() => _isInitialized = true);
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

  Future<void> _toggleAudio() async {
    if (_isPlaying) {
      await _flutterTts.stop();
      setState(() => _isPlaying = false);
      return;
    }

    setState(() => _isPlaying = true);
    final lang = _languages[_selectedLang]!;
    await _flutterTts.setLanguage(lang['tts']!);
    await _flutterTts.speak(widget.explanation);
  }

  Future<void> _changeLang(String lang) async {
    if (_isPlaying) await _flutterTts.stop();
    setState(() {
      _selectedLang = lang;
      _isPlaying = false;
    });
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
                child: _buildPlainContent(),
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
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 26),
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
              child: const Icon(Icons.close, color: Colors.white60, size: 18),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D9E75).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: const Color(0xFF1D9E75).withValues(alpha: 0.4)),
                ),
                child: const Text('TTS',
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
              GestureDetector(
                onTap: _isInitialized ? _toggleAudio : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isPlaying
                          ? [const Color(0xFFE53935), const Color(0xFFB71C1C)]
                          : [const Color(0xFF9C27B0), const Color(0xFF6A1B9A)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: (_isPlaying ? Colors.red : const Color(0xFF9C27B0))
                            .withValues(alpha: 0.35),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!_isInitialized)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
                        _isInitialized
                            ? (_isPlaying ? 'Stop' : 'Listen')
                            : 'Loading...',
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
                      ? 'Telugu audio playing...'
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
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
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            )),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(children: [
        Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.07))),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('Explanation',
              style: TextStyle(
                  color: Colors.white24,
                  fontSize: 11,
                  letterSpacing: 1.5)),
        ),
        Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.07))),
      ]),
    );
  }

  Widget _buildPlainContent() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: SelectableText(
        widget.explanation,
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: const Text('Got it!',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        ),
      ),
    );
  }
}

class LoadingDialog extends StatelessWidget {
  const LoadingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF12121E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: const Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: Color(0xFF9C27B0),
                strokeWidth: 3,
                backgroundColor: Color(0xFF9C27B0),
              ),
            ),
            SizedBox(height: 20),
            Text('AI Tutor is thinking...',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

Future<void> showAiExplanation(
  BuildContext context,
  String topic,
  String explanation,
) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (context) =>
        AiExplanationDialog(topic: topic, explanation: explanation),
  );
}

Future<void> showLoading(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (context) => const LoadingDialog(),
  );
}
