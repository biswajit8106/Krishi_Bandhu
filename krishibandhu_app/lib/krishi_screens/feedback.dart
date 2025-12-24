import 'package:flutter/material.dart';

Future<bool?> showFeedbackDialog(BuildContext context, {String? token}) {
  String? selectedRating;

  Widget _buildRatingOption({
    required String emoji,
    required String label,
    required VoidCallback onSelect,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: onSelect,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.green : Colors.grey[300]!,
                width: isSelected ? 3 : 2,
              ),
              color: isSelected ? Colors.green.withOpacity(0.1) : Colors.white,
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 40)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected
                  ? Colors.green
                  : const Color.fromARGB(255, 215, 214, 214),
            ),
          ),
        ],
      ),
    );
  }

  void _submitFeedback(BuildContext ctx) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text('Thank you! Feedback submitted: $selectedRating'),
        duration: const Duration(seconds: 2),
      ),
    );
    selectedRating = null;
  }

  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'How is your experience with Krishi-Bandhu app?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildRatingOption(
                        emoji: '😞',
                        label: 'Bad',
                        isSelected: selectedRating == 'bad',
                        onSelect: () => setState(() => selectedRating = 'bad'),
                      ),
                      _buildRatingOption(
                        emoji: '😐',
                        label: 'Average',
                        isSelected: selectedRating == 'average',
                        onSelect: () =>
                            setState(() => selectedRating = 'average'),
                      ),
                      _buildRatingOption(
                        emoji: '😊',
                        label: 'Good',
                        isSelected: selectedRating == 'good',
                        onSelect: () => setState(() => selectedRating = 'good'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: selectedRating == null
                          ? null
                          : () {
                              _submitFeedback(dialogContext);
                              Navigator.of(dialogContext).pop(true);
                            },
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.resolveWith((
                          states,
                        ) {
                          if (states.contains(MaterialState.disabled)) {
                            return Colors.grey.shade200;
                          }
                          return Colors.green;
                        }),
                        foregroundColor: MaterialStateProperty.resolveWith((
                          states,
                        ) {
                          if (states.contains(MaterialState.disabled)) {
                            return Colors.grey.shade500;
                          }
                          return Colors.white;
                        }),
                        padding: MaterialStateProperty.all(
                          const EdgeInsets.symmetric(vertical: 14),
                        ),
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      child: const Text(
                        'Submit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 16, color: Color.fromARGB(255, 51, 51, 51)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class FeedbackPage extends StatefulWidget {
  final String token;
  const FeedbackPage({Key? key, required this.token}) : super(key: key);

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  String? selectedRating;
  @override
  void initState() {
    super.initState();
  }

  // The dialog is shown via the top-level `showFeedbackDialog` function.
  // Instance helpers are intentionally omitted; the dialog uses local helpers.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Give Feedback'), elevation: 0),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'We value your feedback!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Help us improve the Krishi Bandhu app by sharing your experience.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color.fromARGB(255, 160, 158, 158),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () =>
                    showFeedbackDialog(context, token: widget.token),
                icon: const Icon(Icons.rate_review),
                label: const Text('Give Feedback'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
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
