import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ContactSupportPage extends StatelessWidget {
  final String token;
  const ContactSupportPage({Key? key, required this.token}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact & Support'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Krishi Bandhu – Contact & Support',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We are always here to assist you. If you have any questions, technical issues, feedback, or need farming-related support through the Krishi Bandhu application, feel free to reach out to us.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.6,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 24),
            _buildContactCard(
              emoji: '📞',
              title: 'Customer Support Helpline',
              items: [
                'Phone: +91 95085 36466',
                'Available: Monday to Saturday, 9:00 AM – 6:00 PM (IST)',
                'For urgent issues or app-related guidance, call our support team directly.',
              ],
            ),
            const SizedBox(height: 16),
            _buildContactCard(
              emoji: '📧',
              title: 'Email Support',
              items: [
                'Email: krishibandhu@gmail.com',
                'Reach us anytime with your queries, feedback, or technical concerns. Our team will respond within 24–48 hours.',
              ],
            ),
            const SizedBox(height: 16),
            _buildContactCard(
              emoji: '🌾',
              title: 'Farmer Assistance & Technical Help',
              items: [
                'Help with app setup, login, or account issues',
                'Support with crop disease detection, climate predictions, or irrigation recommendations',
                'Guidance on how to use AI tools within the app',
                'Reporting bugs, errors, or feature requests',
              ],
            ),
            const SizedBox(height: 16),
            _buildContactCard(
              emoji: '🛠',
              title: 'Developer & Technical Queries (Optional)',
              items: [
                'For advanced or technical inquiries related to integration, APIs, or system behavior, please write to us at our support email with the subject line:',
                '"Technical Query – Krishi Bandhu"',
              ],
            ),
            const SizedBox(height: 16),
            _buildContactCard(
              emoji: '📍',
              title: 'Future Support Channels (Coming Soon)',
              items: [
                'In-app live chat',
                'WhatsApp support',
                'Regional language call centers',
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your feedback helps us improve. Don\'t hesitate to reach out with suggestions or concerns!',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        height: 1.5,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required String emoji,
    required String title,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ', style: GoogleFonts.poppins(fontSize: 13)),
                        Expanded(
                          child: Text(
                            item,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              height: 1.5,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
