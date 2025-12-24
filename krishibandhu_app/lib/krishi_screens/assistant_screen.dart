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

import '../helpers/language_helper.dart';
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

  // DEFAULT UI language
  String selectedLanguageUI = "English";

  bool isRecording = false;
  bool isListening = false;
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
      print("Recorder Ready");
    } catch (e) {
      print("Recorder Error: $e");
    }
  }

  Future<void> _setupSpeechToText() async {
    _speech = stt.SpeechToText();
    bool available = await _speech.initialize(
      onStatus: (val) {
        setState(() => isListening = val == "listening");
      },
      onError: (val) {
        setState(() => isListening = false);
        Future.delayed(const Duration(seconds: 1), _startContinuousListening);
      },
    );
  }

  Future<void> _startContinuousListening() async {
    if (!_speech.isAvailable || isListening) return;
    await _stopContinuousListening();

    var status = await Permission.microphone.request();
    if (!status.isGranted) return;

    setState(() => isListening = true);

    final apiLang = LanguageHelper.toApiCode(selectedLanguageUI);
    final localeId = _getLocale(apiLang);

    await _speech.listen(
      onResult: (val) {
        _lastWords = val.recognizedWords;
        if (val.finalResult) _processVoiceInput(_lastWords);
      },
      localeId: localeId,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      listenMode: stt.ListenMode.confirmation,
    );
  }

  Future<void> _stopContinuousListening() async {
    if (_speech.isListening) await _speech.stop();
    setState(() => isListening = false);
  }

  String _getLocale(String apiLang) {
    return {
      "en": "en_US",
      "hi": "hi_IN",
      "or": "or_IN",
      "bn": "bn_IN",
      "mr": "mr_IN",
      "gu": "gu_IN",
      "te": "te_IN",
      "ta": "ta_IN",
      "pa": "pa_IN",
      "ml": "ml_IN",
      "ur": "ur_IN",
      "kn": "kn_IN",
    }[apiLang] ??
        "en_US";
  }

  Future<void> _processVoiceInput(String speechText) async {
    if (speechText.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
          text: "🎤 Listening...", isUser: false, timestamp: DateTime.now()));
    });

    final reply = await _callBackendText(speechText);

    setState(() {
      _messages.removeLast();
      _messages.add(ChatMessage(
          text: speechText, isUser: true, timestamp: DateTime.now()));
      _messages.add(ChatMessage(
          text: reply["response"],
          isUser: false,
          timestamp: DateTime.now(),
          audioUrl: reply["audio_url"]));
    });

    if (reply["audio_url"] != null) {
      _player.play(UrlSource(reply["audio_url"]));
    }

    _scrollToBottom();

    await Future.delayed(const Duration(seconds: 2));
    _startContinuousListening();
  }

  // UI --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            const Text("Smart Assistant"),
            if (isListening)
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: _buildListeningIndicator(),
              )
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.language), onPressed: _showLanguageSelector),
          IconButton(icon: Icon(isRecording ? Icons.mic : Icons.mic_none), onPressed: _toggleRecording)
        ],
      ),
      body: Column(children: [
        _buildQuickActions(),
        Expanded(child: _buildChatList()),
        _buildMessageInput(),
      ]),
      bottomNavigationBar: BottomNavBar(currentIndex: 4, token: widget.token),
    );
  }

  Widget _buildListeningIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
      child: const Row(children: [
        Icon(Icons.mic, color: Colors.white, size: 16),
        SizedBox(width: 4),
        Text("Listening", style: TextStyle(color: Colors.white, fontSize: 12))
      ]),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        QuickActionButton(
            icon: Icons.eco,
            label: "Crop Advice",
            onTap: () => _sendMessage("Give me advice about my rice crop")),
        const SizedBox(width: 8),
        QuickActionButton(
            icon: Icons.water_drop,
            label: "Irrigation",
            onTap: () => _sendMessage("Help me with irrigation scheduling")),
        const SizedBox(width: 8),
        QuickActionButton(
            icon: Icons.wb_sunny,
            label: "Weather",
            onTap: () => _sendMessage("What is the farming weather today?")),
      ]),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) => ChatMessageWidget(message: _messages[index]),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _messageController,
            decoration: const InputDecoration(hintText: "Ask me anything..."),
            onSubmitted: (value) => _sendMessage(value.trim()),
          ),
        ),
        IconButton(
            icon: const Icon(Icons.send, color: Colors.green),
            onPressed: () => _sendMessage(_messageController.text.trim()))
      ]),
    );
  }

  // CORE CHAT FLOW -----------------------------------------------------------------

  void _addWelcomeMessage() {
    _messages.add(ChatMessage(
        text: "Hello! I am your KrishiBandhu Smart Assistant. How can I help you?",
        isUser: false,
        timestamp: DateTime.now()));
  }

  Future<void> _sendMessage(String text) async {
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
    });

    _messageController.clear();
    _scrollToBottom();

    final reply = await _callBackendText(text);

    setState(() {
      _messages.add(ChatMessage(
          text: reply["response"],
          isUser: false,
          timestamp: DateTime.now(),
          audioUrl: reply["audio_url"]));
    });

    if (reply["audio_url"] != null) _player.play(UrlSource(reply["audio_url"]));

    _scrollToBottom();
  }

  Future<Map<String, dynamic>> _callBackendText(String prompt) async {
    final apiLang = LanguageHelper.toApiCode(selectedLanguageUI);
    final api = ApiService();
    return await api.assistantChat(widget.token, prompt, apiLang);
  }

  // VOICE RECORDING ----------------------------------------------------------------

  Future<void> _toggleRecording() async {
    if (!isRecording) {
      var status = await Permission.microphone.request();
      if (!status.isGranted) return;
      await _startRecording();
    } else {
      await _stopRecording();
    }
  }

  Future<void> _startRecording() async {
    setState(() => isRecording = true);

    final dir = await getApplicationDocumentsDirectory();
    final filePath = "${dir.path}/voice_input.wav";

    await _recorder.startRecorder(toFile: filePath, codec: Codec.pcm16WAV);
  }

  Future<void> _stopRecording() async {
    setState(() => isRecording = false);
    final path = await _recorder.stopRecorder();
    if (path == null) return;
    await _sendVoiceToBackend(File(path));
  }

  Future<void> _sendVoiceToBackend(File audio) async {
    final api = ApiService();
    final apiLang = LanguageHelper.toApiCode(selectedLanguageUI);

    final data =
        await api.assistantVoice(widget.token, audio, apiLang);

    setState(() {
      _messages.add(ChatMessage(
          text: data["user_voice_text"],
          isUser: true,
          timestamp: DateTime.now()));
      _messages.add(ChatMessage(
          text: data["response"],
          isUser: false,
          timestamp: DateTime.now(),
          audioUrl: data["audio_url"]));
    });

    if (data["audio_url"] != null) {
      try {
        await _player.play(UrlSource(data["audio_url"]));
      } catch (e) {
        _messages.add(ChatMessage(
            text: "Audio playback failed. Please check your connection.",
            isUser: false,
            timestamp: DateTime.now()));
      }
    }

    _scrollToBottom();
  }

  // LANGUAGE SELECTOR --------------------------------------------------------------

  void _showLanguageSelector() {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text("Choose Language"),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                _langTile("English", "English"),
                _langTile("Hindi (हिंदी)", "हिन्दी"),
                _langTile("Odia (ଓଡିଆ)", "ଓଡ଼ିଆ"),
                _langTile("Bengali (বাংলা)", "বাংলা"),
              ]),
            ));
  }

  Widget _langTile(String title, String uiLang) {
    return ListTile(
      title: Text(title),
      trailing: selectedLanguageUI == uiLang
          ? const Icon(Icons.check_circle)
          : null,
      onTap: () {
        setState(() => selectedLanguageUI = uiLang);
        Navigator.pop(context);
      },
    );
  }

  // SCROLL BOTTOM ------------------------------------------------------------------

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
