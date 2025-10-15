// ------------------ Farmer Virtual Assistant Screen ------------------

void main() => runApp(KrishiBandhuApp());

class FarmerAssistantScreen extends StatefulWidget {
  @override
  _FarmerAssistantScreenState createState() => _FarmerAssistantScreenScreenState();
}

class _FarmerAssistantScreenScreenState extends State<FarmerAssistantScreen> {
  final List<Map<String, String>> messages = [
    {'who': 'bot', 'text': 'नमस्ते! कैसे मदद कर सकता हूँ?'},
  ];
  final TextEditingController _controller = TextEditingController();
  String _language = 'English';

  void _send(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      messages.add({'who': 'user', 'text': text});
      messages.add({'who': 'bot', 'text': 'Processing... (mock response)'});
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🤖 KrishiBandhu Assistant'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => setState(() => _language = v),
            itemBuilder: (_) => ['English', 'हिन्दी', 'मराठी', 'తెలుగు'].map((e) => PopupMenuItem(child: Text(e), value: e)).toList(),
            child: Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Row(children: [Icon(Icons.language), SizedBox(width: 6), Text(_language)])),
          )
        ],
      ),
      body: Column(
        children: [
          // Suggested prompts
          Container(
            height: 70,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _PromptChip(label: 'Check Market Prices', onTap: () => _send('Check Market Prices')),
                _PromptChip(label: 'Govt. Schemes Available', onTap: () => _send('Govt. Schemes')),
                _PromptChip(label: 'Disease Solutions', onTap: () => _send('Disease Solutions')),
                _PromptChip(label: 'Farming Tips', onTap: () => _send('Farming Tips')),
              ],
            ),
          ),

          // Chat area
          Expanded(
            child: Container(
              padding: EdgeInsets.all(12),
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, i) {
                  final m = messages[i];
                  final isBot = m['who'] == 'bot';
                  return Align(
                    alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 6),
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(color: isBot ? Colors.white : Colors.green[100], borderRadius: BorderRadius.circular(8)),
                      child: Text(m['text']!),
                    ),
                  );
                },
              ),
            ),
          ),

          // Input bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
              child: Row(
                children: [
                  IconButton(icon: Icon(Icons.mic), onPressed: () {}),
                  Expanded(
                    child: TextField(controller: _controller, decoration: InputDecoration(hintText: 'Ask KrishiBandhu...')),
                  ),
                  IconButton(icon: Icon(Icons.send), onPressed: () => _send(_controller.text))
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _PromptChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PromptChip({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(label: Text(label), onPressed: onTap),
    );
  }
}