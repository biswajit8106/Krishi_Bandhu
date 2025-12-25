import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../helpers/language_helper.dart';
import '../models/chat_models.dart';
import '../services/api_service.dart';
import '../widgets/chat_message.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/bottom_nav_bar.dart';

enum EmotionType { happy, neutral, concern, urgent }

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
  bool isSpeaking = false;
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
        if (mounted) {
          setState(() => isListening = status == "listening");
        }
      },
      onError: (_) {
        if (mounted) setState(() => isListening = false);
      },
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

  // ===================== UTILITIES =====================

  String _sanitizeResponse(String text) {
  return text
      .replaceAll('*', '')                // ✅ only asterisk removed
      .replaceAll(RegExp(r'\s+'), ' ')    // spacing cleanup
      .trim();
}


  Future<void> _stopSpeaking() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
    if (mounted) setState(() => isSpeaking = false);
  }

  EmotionType _detectEmotion(String text) {
    final t = text.toLowerCase();

    if (t.contains("warning") ||
        t.contains("alert") ||
        t.contains("danger") ||
        t.contains("immediately")) {
      return EmotionType.urgent;
    }

    if (t.contains("risk") ||
        t.contains("careful") ||
        t.contains("disease") ||
        t.contains("problem")) {
      return EmotionType.concern;
    }

    if (t.contains("good") ||
        t.contains("success") ||
        t.contains("increase") ||
        t.contains("profit")) {
      return EmotionType.happy;
    }

    return EmotionType.neutral;
  }

  // ===================== MESSAGE HELPERS =====================

  void _addMessage(ChatMessage message) {
    setState(() => _messages.add(message));
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

  // ===================== UI =====================

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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70),
        child: _buildMicFab(),
      ),
      bottomNavigationBar:
          BottomNavBar(currentIndex: 4, token: widget.token),
    );
  }

  Widget _buildMicFab() {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (isListening)
          const _PulseRing(color: Colors.red, size: 90),
        if (isSpeaking)
          const _PulseRing(color: Colors.green, size: 80),
        FloatingActionButton(
          backgroundColor:
              isListening ? Colors.red : Colors.green,
          onPressed: _onTapListen,
          child: AnimatedScale(
            scale: isSpeaking ? 1.15 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Icon(
              isListening
                  ? Icons.graphic_eq
                  : isSpeaking
                      ? Icons.volume_up
                      : Icons.mic,
              size: 30,
              color: Colors.white,
            ),
          ),
        ),
      ],
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
      itemBuilder: (_, i) => ChatMessageWidget(message: _messages[i]),
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
              onTap: _stopSpeaking,
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

  // ===================== TEXT CHAT =====================

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    await _stopSpeaking();
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

  // ===================== VOICE =====================

  Future<void> _onTapListen() async {
    await _stopSpeaking();

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

    await _stopSpeaking();

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

  // ===================== BACKEND =====================

  Future<Map<String, dynamic>> _callBackend(String text) async {
    final api = ApiService();
    // Pass the UI language label — ApiService will normalize it.
    return api.assistantChat(widget.token, text, selectedLanguageUI);
  }

  // ===================== TTS (Emotion-based) =====================

  Future<void> _speak(String text) async {
    if (text.isEmpty) return;

    final emotion = _detectEmotion(text);
    await _flutterTts.stop();
    await _flutterTts.setLanguage(
      _getTtsLocale(LanguageHelper.toApiCode(selectedLanguageUI)),
    );

    switch (emotion) {
      case EmotionType.happy:
        await _flutterTts.setPitch(1.2);
        await _flutterTts.setSpeechRate(0.55);
        break;
      case EmotionType.concern:
        await _flutterTts.setPitch(0.9);
        await _flutterTts.setSpeechRate(0.45);
        break;
      case EmotionType.urgent:
        await _flutterTts.setPitch(1.3);
        await _flutterTts.setSpeechRate(0.65);
        break;
      case EmotionType.neutral:
      default:
        await _flutterTts.setPitch(1.0);
        await _flutterTts.setSpeechRate(0.5);
    }

    setState(() => isSpeaking = true);

    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => isSpeaking = false);
    });
    _flutterTts.setErrorHandler((_) {
      if (mounted) setState(() => isSpeaking = false);
    });

    await _flutterTts.speak(text);
  }

  // ===================== LANGUAGE =====================

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

// ===================== ANIMATIONS =====================

class _PulseRing extends StatefulWidget {
  final Color color;
  final double size;
  const _PulseRing({required this.color, required this.size});

  @override
  State<_PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<_PulseRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final scale = 1 + _controller.value;
        final opacity = 1 - _controller.value;

        return Container(
          width: widget.size * scale,
          height: widget.size * scale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(opacity * 0.3),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

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
              height: 20 +
                  (_controller.value * 25 * (i.isEven ? 1 : 0.6)),
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
