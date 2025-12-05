import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../models/chat_models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_message.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/bottom_nav_bar.dart';

class AssistantScreen extends StatefulWidget {
  final String token;
  const AssistantScreen({super.key, required this.token});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  String selectedLanguage = "en";
  bool isRecording = false;
  bool isListening = false; // New state for continuous listening
  String _lastWords = '';

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final AudioPlayer _player = AudioPlayer();
  late stt.SpeechToText _speech;

  @override
  void initState() {
    super.initState();
    _setupRecorder();
    _setupSpeechToText();
    _addWelcomeMessage();
    _startContinuousListening();
  }

  Future<void> _setupRecorder() async {
    try {
      await _recorder.openRecorder();
      await _recorder.setSubscriptionDuration(const Duration(milliseconds: 200));
      print("Recorder setup successful");
    } catch (e) {
      print("Error setting up recorder: $e");
    }
  }

  Future<void> _setupSpeechToText() async {
    _speech = stt.SpeechToText();
    bool available = await _speech.initialize(
      onStatus: (val) {
        print('STT Status: $val');
        if (val == 'listening') {
          setState(() => isListening = true);
        } else if (val == 'notListening') {
          setState(() => isListening = false);
        }
      },
      onError: (val) {
        print('STT Error: $val');
        setState(() => isListening = false);
        // Auto-retry after error
        Future.delayed(const Duration(seconds: 1), () {
          if (!isListening) {
            _startContinuousListening();
          }
        });
      },
    );
    if (available) {
      print("Speech to text initialized successfully");
    } else {
      print("Speech to text not available");
    }
  }

  Future<void> _startContinuousListening() async {
    if (!_speech.isAvailable || isListening) return;

    // Stop any existing listening session first
    await _stopContinuousListening();

    // Request microphone permission
    var status = await Permission.microphone.request();
    if (!status.isGranted) {
      print("Microphone permission denied");
      setState(() => isListening = false);
      return;
    }

    setState(() => isListening = true);

    try {
      await _speech.listen(
        onResult: (val) {
          setState(() {
            _lastWords = val.recognizedWords;
          });

          if (val.finalResult) {
            // User finished speaking, process the message
            _processVoiceInput(_lastWords);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3), // Reduced pause time for better responsiveness
        partialResults: true,
        localeId: _getLocaleId(),
        onSoundLevelChange: (level) {
          // Show listening indicator when sound is detected
          if (level > 0.5 && !isListening) {
            setState(() => isListening = true);
          }
        },
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );
    } catch (e) {
      print("Error starting continuous listening: $e");
      setState(() => isListening = false);
      // Retry after a delay
      await Future.delayed(const Duration(seconds: 2));
      _startContinuousListening();
    }
  }

  Future<void> _stopContinuousListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
    setState(() => isListening = false);
  }

  String _getLocaleId() {
    switch (selectedLanguage) {
      case "en":
        return "en_US";
      case "hi":
        return "hi_IN";
      case "kn":
        return "kn_IN";
      case "te":
        return "te_IN";
      case "ta":
        return "ta_IN";
      case "mr":
        return "mr_IN";
      case "gu":
        return "gu_IN";
      case "bn":
        return "bn_IN";
      case "pa":
        return "pa_IN";
      case "ml":
        return "ml_IN";
      case "or":
        return "or_IN";
      case "ur":
        return "ur_IN";
      default:
        return "en_US";
    }
  }

  Future<void> _processVoiceInput(String speechText) async {
    if (speechText.isEmpty) return;

    // Show listening indicator
    setState(() {
      _messages.add(ChatMessage(
          text: "🎤 Listening...",
          isUser: false,
          timestamp: DateTime.now()));
    });
    _scrollToBottom();

    // Send to backend for processing
    final reply = await _callBackendText(speechText);

    // Remove listening message and add user message
    setState(() {
      _messages.removeLast(); // Remove listening message
      _messages.add(ChatMessage(
          text: speechText,
          isUser: true,
          timestamp: DateTime.now()));
    });

    // Add AI response
    setState(() {
      _messages.add(ChatMessage(
          text: reply["response"],
          isUser: false,
          timestamp: DateTime.now(),
          audioUrl: reply["audio_url"]));
    });

    // Play assistant voice
    if (reply["audio_url"] != null) {
      _player.play(UrlSource(reply["audio_url"]));
    }

    _scrollToBottom();

    // Restart listening after response
    await Future.delayed(const Duration(seconds: 2));
    _startContinuousListening();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _recorder.closeRecorder();
    super.dispose();
  }

  // --------------------------------------------------------------------
  // UI
  // --------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Smart Assistant'),
            if (isListening) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.mic, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text('Listening', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: _showLanguageSelector,
          ),
          IconButton(
            icon: Icon(isRecording ? Icons.mic : Icons.mic_none),
            onPressed: _toggleRecording,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildQuickActions(),
          Expanded(child: _buildChatList()),
          _buildMessageInput(),
        ],
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 4, token: widget.token),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Quick Actions",
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              QuickActionButton(
                  icon: Icons.eco,
                  label: "Crop Advice",
                  onTap: () => _sendMessage("Give me advice about my rice crop")),
              const SizedBox(width: 8),
              QuickActionButton(
                  icon: Icons.water_drop,
                  label: "Irrigation",
                  onTap: () =>
                      _sendMessage("Help me with irrigation scheduling")),
              const SizedBox(width: 8),
              QuickActionButton(
                  icon: Icons.wb_sunny,
                  label: "Weather",
                  onTap: () =>
                      _sendMessage("What is the farming weather today?")),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return ChatMessageWidget(message: _messages[index]);
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration:
                  const InputDecoration(hintText: "Ask me anything..."),
              onSubmitted: (value) => _sendMessage(value.trim()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.green),
            onPressed: () {
              _sendMessage(_messageController.text.trim());
            },
          )
        ],
      ),
    );
  }

  // --------------------------------------------------------------------
  // CHAT FUNCTIONALITY
  // --------------------------------------------------------------------

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(ChatMessage(
          text:
              "Hello! I am your KrishiBandhu Smart Assistant. How can I help you?",
          isUser: false,
          timestamp: DateTime.now()));
    });
    print("Welcome message added");
  }

  Future<void> _sendMessage(String text) async {
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
          text: text, isUser: true, timestamp: DateTime.now()));
    });

    _messageController.clear();
    _scrollToBottom();

    // Send text to backend
    final reply = await _callBackendText(text);

    setState(() {
      _messages.add(ChatMessage(
          text: reply["response"],
          isUser: false,
          timestamp: DateTime.now(),
          audioUrl: reply["audio_url"]));
    });

    // Play assistant voice
    if (reply["audio_url"] != null) {
      _player.play(UrlSource(reply["audio_url"]));
    }

    _scrollToBottom();
  }

  Future<Map<String, dynamic>> _callBackendText(String prompt) async {
    final apiService = ApiService();
    return await apiService.assistantChat(widget.token, prompt, selectedLanguage);
  }

  // --------------------------------------------------------------------
  // VOICE RECORDING + BACKEND SEND
  // --------------------------------------------------------------------

  Future<void> _toggleRecording() async {
    if (!isRecording) {
      // Request microphone permission
      var status = await Permission.microphone.request();
      if (status.isGranted) {
        await _startRecording();
      } else {
        // Show a snackbar or dialog to inform user
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required for voice input')),
        );
      }
    } else {
      await _stopRecording();
    }
  }

  Future<void> _startRecording() async {
    setState(() => isRecording = true);

    // Add welcome message when starting recording
    setState(() {
      _messages.add(ChatMessage(
          text: "Welcome to KrishiBandhu Assistant! How can I help you today?",
          isUser: false,
          timestamp: DateTime.now()));
    });
    _scrollToBottom();

    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/voice_input.wav';

    await _recorder.startRecorder(
      toFile: filePath,
      codec: Codec.pcm16WAV,
    );
  }

  Future<void> _stopRecording() async {
    setState(() => isRecording = false);

    final path = await _recorder.stopRecorder();
    final audioFile = File(path!);

    await _sendVoiceToBackend(audioFile);
  }

  Future<void> _sendVoiceToBackend(File audio) async {
    final apiService = ApiService();
    final data = await apiService.assistantVoice(widget.token, audio, selectedLanguage);

    // Show user speech text
    setState(() {
      _messages.add(ChatMessage(
          text: data["user_voice_text"],
          isUser: true,
          timestamp: DateTime.now()));
    });

    // Show AI response
    setState(() {
      _messages.add(ChatMessage(
          text: data["response"],
          isUser: false,
          timestamp: DateTime.now(),
          audioUrl: data["audio_url"]));
    });

    // Play voice response
    if (data["audio_url"] != null) {
      try {
        await _player.play(UrlSource(data["audio_url"]));
        print("Playing audio from: ${data["audio_url"]}");
      } catch (e) {
        print("Error playing audio: $e");
        // Show error message to user
        setState(() {
          _messages.add(ChatMessage(
              text: "Audio playback failed. Please check your connection.",
              isUser: false,
              timestamp: DateTime.now()));
        });
        _scrollToBottom();
      }
    }

    _scrollToBottom();
  }

  // --------------------------------------------------------------------
  // LANGUAGE SELECTOR
  // --------------------------------------------------------------------

  void _showLanguageSelector() {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text("Choose Language"),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                _langTile("English", "en"),
                _langTile("Hindi (हिंदी)", "hi"),
                _langTile("Odia (ଓଡ଼ିଆ)", "or"),
                _langTile("Bengali (বাংলা)", "bn"),
              ]),
            ));
  }

  Widget _langTile(String title, String code) {
    return ListTile(
      title: Text(title),
      trailing:
          selectedLanguage == code ? const Icon(Icons.check_circle) : null,
      onTap: () {
        setState(() => selectedLanguage = code);
        Navigator.pop(context);
      },
    );
  }

  // --------------------------------------------------------------------

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    });
  }
}
