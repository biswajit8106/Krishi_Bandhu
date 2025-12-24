import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsConditionsPage extends StatelessWidget {
  final String token;
  const TermsConditionsPage({Key? key, required this.token}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Krishi Bandhu – Terms & Conditions',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Effective Date: 11.11.2025',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Welcome to Krishi Bandhu, a Smart AI application designed to provide AI-driven farming solutions, crop insights, and virtual assistance. By using this application ("App"), you agree to comply with and be bound by the following terms and conditions. If you do not agree, do not use the App.',
              style: GoogleFonts.poppins(fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 20),
            _buildSection('1. Use of the App', [
              'The App is intended for informational and educational purposes to assist farmers in managing crops, predicting climate, and optimizing farming operations.',
              'Users must be 18 years or older or legally permitted to enter into contracts in their jurisdiction.',
              'Users agree to provide accurate and current information when using the App.',
            ]),
            _buildSection('2. Intellectual Property', [
              'All software, AI models, algorithms, databases, designs, and content within Krishi Bandhu are the intellectual property of the developers and/or their licensors.',
              'Users are granted a limited, non-exclusive, non-transferable license to use the App for personal or farm-related purposes only.',
              'No content from the App may be copied, reproduced, modified, distributed, or commercially exploited without prior written permission.',
            ]),
            _buildSection('3. User Responsibilities', [
              'Users are responsible for their own actions and decisions based on App recommendations.',
              'The App provides guidance on crop disease detection, irrigation, fertilizer application, and market trends. Users must independently verify and apply professional judgment before acting.',
              'Users must not misuse, reverse-engineer, or attempt to manipulate the App\'s AI systems or data.',
            ]),
            _buildSection('4. Data Collection & Privacy', [
              'Krishi Bandhu collects data such as farm location, soil parameters, crop images, and user inputs to improve AI predictions and provide personalized recommendations.',
              'By using the App, users consent to the collection, storage, and processing of such data in accordance with applicable privacy laws.',
              'Personal data will not be shared with third parties except as required by law or as described in the App\'s Privacy Policy.',
            ]),
            _buildSection('5. Disclaimers', [
              'The App is provided "as is" and without warranties of any kind, whether express or implied.',
              'Krishi Bandhu does not guarantee crop yield, disease prevention, or financial outcomes based on the App\'s recommendations.',
              'Use of the App is at the user\'s own risk. The developers are not liable for any losses, damages, or injuries resulting from use or inability to use the App.',
            ]),
            _buildSection('6. Limitation of Liability', [
              'Under no circumstances shall the developers, affiliates, or contributors be liable for indirect, incidental, special, or consequential damages, including lost profits or crop losses.',
              'The total liability, if any, shall not exceed the amount paid by the user for accessing the App, if applicable.',
            ]),
            _buildSection('7. Third-Party Services', [
              'The App may integrate third-party APIs (e.g., weather, satellite, NLP) or services. The developers are not responsible for the accuracy, availability, or reliability of such third-party services.',
            ]),
            _buildSection('8. Termination', [
              'The developers may suspend or terminate access to the App for violation of these Terms & Conditions or misuse of the App, without prior notice.',
              'Upon termination, all rights granted to the user will immediately cease.',
            ]),
            _buildSection('9. Governing Law', [
              'These Terms & Conditions are governed by the laws of India.',
              'Any disputes arising from the use of the App will be subject to the exclusive jurisdiction of the courts in India.',
            ]),
            _buildSection('10. Changes to Terms', [
              'The developers reserve the right to update or modify these Terms & Conditions at any time. Users will be notified of significant changes via the App or email.',
              'Continued use of the App after changes constitutes acceptance of the updated terms.',
            ]),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact Information:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'For questions or concerns regarding these Terms & Conditions, please contact:',
                    style: GoogleFonts.poppins(fontSize: 12, height: 1.6),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Email: krishibandhu@gmail.com',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Phone: +91 9508536466',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.blue,
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

  Widget _buildSection(String title, List<String> points) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: points
                .map(
                  (point) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ', style: GoogleFonts.poppins(fontSize: 14)),
                        Expanded(
                          child: Text(
                            point,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
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
