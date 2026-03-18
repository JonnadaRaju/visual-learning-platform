import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../services/ai_service.dart';

class AIAssistantScreen extends ConsumerStatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  ConsumerState<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends ConsumerState<AIAssistantScreen> {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  
  bool _speechEnabled = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isLoading = false;
  
  String _lastWords = '';
  String _answer = '';
  String _currentQuestion = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onError: (error) => print('Speech error: $error'),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (_isListening && _lastWords.isNotEmpty) {
            _askQuestion(_lastWords);
          }
          setState(() => _isListening = false);
        }
      },
    );
    setState(() {});
  }

  void _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setCompletionHandler(() {
      setState(() => _isSpeaking = false);
    });
  }

  void _startListening() async {
    _lastWords = '';
    await _speechToText.listen(
      onResult: (result) => setState(() {
        _lastWords = result.recognizedWords;
      }),
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
    );
    setState(() => _isListening = true);
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() => _isListening = false);
    if (_lastWords.isNotEmpty) {
      _askQuestion(_lastWords);
    }
  }

  void _askQuestion(String question) async {
    if (question.isEmpty) return;
    
    setState(() {
      _currentQuestion = question;
      _answer = '';
      _isLoading = true;
    });

    try {
      final aiService = ref.read(aiServiceProvider);
      final response = await aiService.askQuestion(question);
      setState(() {
        _answer = response;
        _isLoading = false;
      });
      _speakAnswer(response);
    } catch (e) {
      setState(() {
        _answer = 'Sorry, I couldn\'t get an answer. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _speakAnswer(String answer) async {
    setState(() => _isSpeaking = true);
    await _flutterTts.speak(answer);
  }

  void _stopSpeaking() async {
    await _flutterTts.stop();
    setState(() => _isSpeaking = false);
  }

  @override
  void dispose() {
    _speechToText.cancel();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Tutor'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade100,
              Colors.deepPurple.shade50,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.smart_toy,
                      size: 60,
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isListening
                          ? 'Listening...'
                          : _isLoading
                              ? 'Thinking...'
                              : _isSpeaking
                                  ? 'Speaking...'
                                  : 'Tap mic and ask a question!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (_lastWords.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: Colors.blue),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _lastWords,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              if (_answer.isNotEmpty)
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.smart_toy, color: Colors.green),
                              const SizedBox(width: 10),
                              Text(
                                'AI Tutor says:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _answer,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildButton(
                    icon: _isListening ? Icons.stop : Icons.mic,
                    color: _isListening ? Colors.red : Colors.deepPurple,
                    label: _isListening ? 'Stop' : 'Ask',
                    onPressed: _speechEnabled
                        ? (_isListening ? _stopListening : _startListening)
                        : null,
                  ),
                  if (_answer.isNotEmpty)
                    _buildButton(
                      icon: _isSpeaking ? Icons.stop : Icons.volume_up,
                      color: _isSpeaking ? Colors.orange : Colors.green,
                      label: _isSpeaking ? 'Stop' : 'Speak',
                      onPressed:
                          _isSpeaking ? _stopSpeaking : () => _speakAnswer(_answer),
                    ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return Column(
      children: [
        FloatingActionButton(
          heroTag: label,
          onPressed: onPressed,
          backgroundColor: color,
          child: Icon(icon, size: 30, color: Colors.white),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
