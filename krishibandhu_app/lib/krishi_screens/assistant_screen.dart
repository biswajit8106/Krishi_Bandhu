import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../helpers/language_helper.dart';
import '../models/chat_models.dart';
import '../services/api_service.dart';
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

  String selectedLanguageUI = "English";

  bool isListening = false;
  String _lastWords = "";

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final AudioPlayer _player = AudioPlayer();
  late FlutterTts _flutterTts;
  late stt.SpeechToText _speech;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _speech = stt.SpeechToText();
    await _speech.initialize(
      onStatus: (status) {
        setState(() => isListening = status == "listening");
      },
      onError: (_) => setState(() => isListening = false),
    );

    _flutterTts = FlutterTts();
    await _recorder.openRecorder();

    _addMessage(
      ChatMessage(
        text: "Hello! I am your KrishiBandhu Assistant 🌾",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  // ================= SANITIZER =================

  String _sanitizeResponse(String text) {
    return text
        .replaceAll('*', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // ================= MESSAGE HELPERS =================

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    _scrollBottom();
  }

  void _scrollBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("KrishiBandhu Assistant"),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: _showLanguageSelector,
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildMicFab(),
      bottomNavigationBar:
          BottomNavBar(currentIndex: 4, token: widget.token),
    );
  }

  Widget _buildMicFab() {
    return FloatingActionButton(
      backgroundColor: isListening ? Colors.red : Colors.green,
      onPressed: _onTapListen,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: Icon(
          isListening ? Icons.graphic_eq : Icons.mic,
          key: ValueKey(isListening),
          size: 30,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          QuickActionButton(
            icon: Icons.eco,
            label: "Crop Advice",
            onTap: () => _sendMessage("Give me crop advice"),
          ),
          const SizedBox(width: 8),
          QuickActionButton(
            icon: Icons.water_drop,
            label: "Irrigation",
            onTap: () => _sendMessage("Irrigation schedule"),
          ),
          const SizedBox(width: 8),
          QuickActionButton(
            icon: Icons.wb_sunny,
            label: "Weather",
            onTap: () => _sendMessage("Today's weather"),
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
      itemBuilder: (_, i) {
        return ChatMessageWidget(message: _messages[i]);
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
                  const InputDecoration(hintText: "Ask something..."),
              onSubmitted: _sendMessage,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.green),
            onPressed: () => _sendMessage(_messageController.text),
          ),
        ],
      ),
    );
  }

  // ================= TEXT CHAT =================

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _messageController.clear();

    final cleanUserText = _sanitizeResponse(text);

    _addMessage(ChatMessage(
      text: cleanUserText,
      isUser: true,
      timestamp: DateTime.now(),
    ));

    final reply = await _callBackend(cleanUserText);
    final cleanReply = _sanitizeResponse(reply["response"]);

    _addMessage(ChatMessage(
      text: cleanReply,
      isUser: false,
      timestamp: DateTime.now(),
    ));

    await _speak(cleanReply);
  }

  // ================= VOICE =================

  Future<void> _onTapListen() async {
    var mic = await Permission.microphone.request();
    if (!mic.isGranted) return;

    final locale =
        _getLocale(LanguageHelper.toApiCode(selectedLanguageUI));

    _showListeningDialog();

    await _speech.listen(
      localeId: locale,
      listenFor: const Duration(seconds: 30),
      onResult: (result) async {
        _lastWords = result.recognizedWords;
        if (result.finalResult) {
          await _speech.stop();
          Navigator.pop(context);
          _processVoiceInput(_lastWords);
        }
      },
    );
  }

  void _showListeningDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            WaveformAnimation(),
            SizedBox(height: 12),
            Text("Listening… Speak now"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _speech.stop();
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  Future<void> _processVoiceInput(String text) async {
    if (text.isEmpty) return;

    final cleanUserText = _sanitizeResponse(text);

    _addMessage(ChatMessage(
      text: cleanUserText,
      isUser: true,
      timestamp: DateTime.now(),
    ));

    final reply = await _callBackend(cleanUserText);
    final cleanReply = _sanitizeResponse(reply["response"]);

    _addMessage(ChatMessage(
      text: cleanReply,
      isUser: false,
      timestamp: DateTime.now(),
    ));

    await _speak(cleanReply);
  }

  // ================= BACKEND =================

  Future<Map<String, dynamic>> _callBackend(String text) async {
    final api = ApiService();
    final lang = LanguageHelper.toApiCode(selectedLanguageUI);
    return api.assistantChat(widget.token, text, lang);
  }

  // ================= TTS =================

  Future<void> _speak(String text) async {
    if (text.isEmpty) return;
    await _flutterTts.stop();
    await _flutterTts.setLanguage(
      _getTtsLocale(LanguageHelper.toApiCode(selectedLanguageUI)),
    );
    await _flutterTts.speak(text);
  }

  // ================= LANGUAGE =================

  void _showLanguageSelector() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Choose Language"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _lang("English"),
            _lang("हिन्दी"),
            _lang("বাংলা"),
            _lang("ଓଡ଼ିଆ"),
          ],
        ),
      ),
    );
  }

  Widget _lang(String lang) => ListTile(
        title: Text(lang),
        trailing:
            selectedLanguageUI == lang ? const Icon(Icons.check) : null,
        onTap: () {
          setState(() => selectedLanguageUI = lang);
          Navigator.pop(context);
        },
      );

  String _getLocale(String lang) =>
      {"hi": "hi_IN", "bn": "bn_IN", "or": "or_IN"}[lang] ?? "en_US";

  String _getTtsLocale(String lang) =>
      {"hi": "hi-IN", "bn": "bn-IN", "or": "or-IN"}[lang] ?? "en-US";

  @override
  void dispose() {
    _speech.stop();
    _flutterTts.stop();
    _recorder.closeRecorder();
    _player.dispose();
    super.dispose();
  }
}

// ================= WAVEFORM =================

class WaveformAnimation extends StatefulWidget {
  const WaveformAnimation({super.key});

  @override
  State<WaveformAnimation> createState() => _WaveformAnimationState();
}

class _WaveformAnimationState extends State<WaveformAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          5,
          (i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              width: 6,
              height: 20 + (_controller.value * 25 * (i.isEven ? 1 : 0.6)),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
