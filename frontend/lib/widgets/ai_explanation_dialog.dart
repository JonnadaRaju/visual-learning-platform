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

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isPlaying = false);
    });
    
    _flutterTts.setErrorHandler((msg) {
      if (mounted) setState(() => _isPlaying = false);
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
      setState(() => _isPlaying = false);
      return;
    }
    
    setState(() => _isPlaying = true);
    await _flutterTts.speak(widget.explanation);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
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
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.volume_up, color: Color(0xFF9C27B0), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tap to listen to explanation',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 15,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.stop_circle : Icons.play_circle_filled,
                        color: const Color(0xFF9C27B0),
                        size: 40,
                      ),
                      onPressed: _isInitialized ? _playAudio : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(height: 1, color: Colors.white12),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    widget.explanation,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      height: 1.7,
                      letterSpacing: 0.2,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
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
