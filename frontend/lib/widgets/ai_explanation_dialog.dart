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

class _AiExplanationDialogState extends State<AiExplanationDialog> {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlaying = false;
  bool _isInitialized = false;
  String _selectedLanguage = 'en-US';
  int _currentWordIndex = -1;
  List<String> _words = [];

  final Map<String, Map<String, String>> _languages = {
    'en-US': {'name': 'English', 'code': 'en-US'},
    'te-IN': {'name': 'Telugu', 'code': 'te-IN'},
  };

  @override
  void initState() {
    super.initState();
    _words = widget.explanation.split(RegExp(r'\s+'));
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage(_selectedLanguage);
    await _flutterTts.setSpeechRate(0.42);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    _flutterTts.setStartHandler(() {
      if (mounted) setState(() => _isPlaying = true);
    });
    
    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentWordIndex = -1;
        });
      }
    });
    
    _flutterTts.setCancelHandler(() {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentWordIndex = -1;
        });
      }
    });
    
    _flutterTts.setErrorHandler((msg) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentWordIndex = -1;
        });
      }
    });

    _flutterTts.setProgressHandler((text, start, end, word) {
      if (mounted) {
        final wordIndex = _words.indexWhere((w) => w.startsWith(word.substring(0, 1)));
        if (wordIndex >= 0) {
          setState(() => _currentWordIndex = wordIndex);
        }
      }
    });
    
    setState(() => _isInitialized = true);
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  String get _formattedTopic {
    return widget.topic.split('-').map((word) => 
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  Future<void> _playAudio() async {
    if (_isPlaying) {
      await _flutterTts.stop();
      setState(() {
        _isPlaying = false;
        _currentWordIndex = -1;
      });
      return;
    }
    
    setState(() {
      _isPlaying = true;
      _currentWordIndex = 0;
    });
    
    await _flutterTts.setLanguage(_selectedLanguage);
    await _flutterTts.speak(widget.explanation);
  }

  Future<void> _changeLanguage(String langCode) async {
    if (_isPlaying) {
      await _flutterTts.stop();
    }
    setState(() {
      _selectedLanguage = langCode;
      _currentWordIndex = -1;
    });
    await _flutterTts.setLanguage(langCode);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome, 
                      color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Tutor',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formattedTopic,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.record_voice_over, 
                          color: Color(0xFF9C27B0), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Listen in your language',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: _languages.entries.map((entry) {
                        final isSelected = _selectedLanguage == entry.key;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: InkWell(
                            onTap: () => _changeLanguage(entry.key),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? const Color(0xFF9C27B0) 
                                    : Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected 
                                      ? const Color(0xFF9C27B0) 
                                      : Colors.white24,
                                ),
                              ),
                              child: Text(
                                entry.value['name']!,
                                style: TextStyle(
                                  color: isSelected 
                                      ? Colors.white 
                                      : Colors.white70,
                                  fontWeight: isSelected 
                                      ? FontWeight.w600 
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _isPlaying ? 'Tap to stop' : 'Tap to listen',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF9C27B0),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Icon(
                              _isPlaying ? Icons.stop : Icons.play_arrow,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          onPressed: _isInitialized ? _playAudio : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(height: 1, color: Colors.white12),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: _buildHighlightedText(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9C27B0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Got it!',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightedText() {
    final List<TextSpan> spans = [];
    
    for (int i = 0; i < _words.length; i++) {
      final isHighlighted = _isPlaying && 
          _currentWordIndex >= 0 && 
          (i >= _currentWordIndex && i <= _currentWordIndex + 5);
      
      spans.add(
        TextSpan(
          text: _words[i] + ' ',
          style: TextStyle(
            color: isHighlighted 
                ? const Color(0xFFFFD700) 
                : Colors.white,
            fontSize: 17,
            height: 1.7,
            letterSpacing: 0.2,
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w400,
            backgroundColor: isHighlighted 
                ? const Color(0xFF9C27B0).withValues(alpha: 0.3) 
                : Colors.transparent,
          ),
        ),
      );
    }
    
    return RichText(
      text: TextSpan(children: spans),
    );
  }
}

class LoadingDialog extends StatelessWidget {
  const LoadingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: const Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF9C27B0),
              strokeWidth: 3,
            ),
            SizedBox(height: 24),
            Text(
              'Getting explanation...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
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
    builder: (context) => const LoadingDialog(),
  );
}
