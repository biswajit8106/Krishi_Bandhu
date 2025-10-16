import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_message.dart';
import '../widgets/quick_action_button.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Smart Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed: _startVoiceInput,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showOptionsMenu,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildQuickActions(),
          Expanded(
            child: _buildChatList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                QuickActionButton(
                  icon: Icons.eco,
                  label: 'Crop Advice',
                  onTap: () => _sendQuickMessage('Give me advice about my rice crop'),
                ),
                const SizedBox(width: 8),
                QuickActionButton(
                  icon: Icons.water_drop,
                  label: 'Irrigation Help',
                  onTap: () => _sendQuickMessage('Help me with irrigation scheduling'),
                ),
                const SizedBox(width: 8),
                QuickActionButton(
                  icon: Icons.wb_sunny,
                  label: 'Weather Info',
                  onTap: () => _sendQuickMessage('What\'s the weather forecast for farming?'),
                ),
                const SizedBox(width: 8),
                QuickActionButton(
                  icon: Icons.bug_report,
                  label: 'Pest Control',
                  onTap: () => _sendQuickMessage('How to control pests in my field?'),
                ),
                const SizedBox(width: 8),
                QuickActionButton(
                  icon: Icons.analytics,
                  label: 'Farm Analytics',
                  onTap: () => _sendQuickMessage('Show me my farm analytics'),
                ),
              ],
            ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Ask me anything about farming...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: AppTheme.primaryColor),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _sendMessage(value.trim());
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () {
                if (_messageController.text.trim().isNotEmpty) {
                  _sendMessage(_messageController.text.trim());
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _addWelcomeMessage() {
    _messages.add(ChatMessage(
      text: 'Hello! I\'m your smart farming assistant. I can help you with crop advice, irrigation, weather information, pest control, and more. How can I assist you today?',
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  void _sendMessage(String text) {
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
    });

    _messageController.clear();
    _scrollToBottom();

    // Simulate AI response
    Future.delayed(const Duration(seconds: 2), () {
      _simulateAIResponse(text);
    });
  }

  void _sendQuickMessage(String text) {
    _messageController.text = text;
    _sendMessage(text);
  }

  void _simulateAIResponse(String userMessage) {
    String response = _generateAIResponse(userMessage);
    
    setState(() {
      _messages.add(ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });

    _scrollToBottom();
  }

  String _generateAIResponse(String userMessage) {
    String message = userMessage.toLowerCase();
    
    if (message.contains('rice') || message.contains('crop advice')) {
      return 'For rice cultivation, ensure proper water management with 2-3 inches of standing water during the growing season. Monitor for diseases like rice blast and apply appropriate fungicides. Maintain soil pH between 6.0-7.0 for optimal growth.';
    } else if (message.contains('irrigation') || message.contains('watering')) {
      return 'Based on current soil moisture levels, I recommend watering Zone A for 30 minutes and Zone B for 20 minutes. The optimal irrigation schedule is early morning (6 AM) and evening (6 PM) to minimize water loss through evaporation.';
    } else if (message.contains('weather') || message.contains('forecast')) {
      return 'The weather forecast shows sunny conditions for the next 3 days with temperatures ranging from 25-30°C. Light rain is expected on Friday. This is ideal weather for crop growth. Consider scheduling irrigation before the rain to maximize water efficiency.';
    } else if (message.contains('pest') || message.contains('insect')) {
      return 'For pest control, I recommend using integrated pest management (IPM) techniques. Monitor your fields regularly for signs of infestation. Use biological controls like beneficial insects first, then consider organic pesticides if needed. Avoid chemical pesticides during flowering periods.';
    } else if (message.contains('analytics') || message.contains('data')) {
      return 'Your farm analytics show: Crop health at 85%, Soil moisture averaging 68%, Water usage efficiency at 92%, and projected yield increase of 15% compared to last season. Your irrigation system is performing optimally.';
    } else if (message.contains('soil') || message.contains('fertilizer')) {
      return 'For soil health, I recommend testing your soil every 3 months. Based on your crop rotation, apply nitrogen-rich fertilizer during the growing season. Consider using organic compost to improve soil structure and water retention.';
    } else if (message.contains('disease') || message.contains('sick')) {
      return 'If you suspect plant diseases, take clear photos of affected leaves and upload them to the crop disease detection feature. Early detection is crucial for effective treatment. Common signs include discolored leaves, spots, wilting, or unusual growth patterns.';
    } else {
      return 'I understand you\'re asking about "$userMessage". While I have extensive knowledge about farming practices, crop management, irrigation, weather patterns, and pest control, I\'d be happy to provide more specific information if you could clarify your question. You can also use the quick action buttons above for common farming topics.';
    }
  }

  void _scrollToBottom() {
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

  void _startVoiceInput() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voice input feature coming soon!')),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Chat History'),
              onTap: () {
                Navigator.pop(context);
                // Show chat history
              },
            ),
            ListTile(
              leading: const Icon(Icons.clear_all),
              title: const Text('Clear Chat'),
              onTap: () {
                Navigator.pop(context);
                _clearChat();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Assistant Settings'),
              onTap: () {
                Navigator.pop(context);
                // Show settings
              },
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Help & Support'),
              onTap: () {
                Navigator.pop(context);
                // Show help
              },
            ),
          ],
        ),
      ),
    );
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Chat', style: GoogleFonts.poppins()),
        content: const Text('Are you sure you want to clear all chat messages?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _messages.clear();
                _addWelcomeMessage();
              });
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
