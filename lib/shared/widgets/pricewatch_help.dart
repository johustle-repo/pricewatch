import 'package:flutter/material.dart';

class PriceWatchHelp extends StatelessWidget {
  const PriceWatchHelp({super.key});

  @override
  Widget build(BuildContext context) => const Card(
    child: ExpansionTile(
      leading: Icon(Icons.help_outline),
      title: Text('PriceWatch guide'),
      childrenPadding: EdgeInsets.all(16),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How to create an account',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          'Open Create account from the login page. Enter your full name and email, then create and confirm a password. Use at least 8 characters, one uppercase letter, and one number. Submit the form to register as a community user. Vendor accounts are created by an administrator after shop verification.',
        ),
        SizedBox(height: 16),
        Text(
          'What is a CSV file?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          'CSV means Comma-Separated Values. It stores a table as plain text: the first row contains column names and each following row contains a record. You can open it in Excel. PriceWatch imports store and price records and exports reports using CSV.',
        ),
        SizedBox(height: 16),
        Text(
          'Commodities and non-commodities',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          'PriceWatch focuses on market goods such as rice, fish, meat, and vegetables. These are the commodities monitored here. Non-commodities, such as services and differentiated finished products, are outside this market-price monitoring scope. Compare prices using the same product and unit.',
        ),
        SizedBox(height: 16),
        Text('About PriceWatch', style: TextStyle(fontWeight: FontWeight.bold)),
        Text(
          'The application is written in Dart using Flutter. Firebase Cloud Functions use JavaScript.',
        ),
      ],
    ),
  );
}

class VendorDocumentLegend extends StatelessWidget {
  const VendorDocumentLegend({super.key});

  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vendor document legend',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              Chip(
                avatar: Icon(Icons.description, color: Colors.red),
                label: Text('Business permit — RED'),
              ),
              Chip(
                avatar: Icon(Icons.confirmation_number, color: Colors.green),
                label: Text('Ticket — GREEN'),
              ),
            ],
          ),
          Text('Colors identify document types, not verification status.'),
        ],
      ),
    ),
  );
}
