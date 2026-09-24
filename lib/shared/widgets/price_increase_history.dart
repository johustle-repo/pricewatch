import 'package:flutter/material.dart';
import '../../core/utils/app_formatters.dart';
import '../../core/utils/price_increases.dart';
import '../models/price_entry_model.dart';
import '../models/ui_models.dart';

class PriceIncreaseHistory extends StatelessWidget {
  const PriceIncreaseHistory({
    super.key,
    required this.entries,
    required this.stores,
    required this.unit,
  });
  final List<PriceEntryModel> entries;
  final List<StorePriceSnapshot> stores;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final increases = findPriceIncreases(entries);
    return Card(
      child: ExpansionTile(
        initiallyExpanded: increases.isNotEmpty,
        leading: Icon(
          increases.isEmpty ? Icons.history : Icons.warning_amber_rounded,
          color: increases.isEmpty ? null : Colors.deepOrange,
        ),
        title: Text('Recorded price increases (${increases.length})'),
        subtitle: const Text(
          'Compared with the previous record at the same store.',
        ),
        children: [
          if (increases.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No increases found in the available records. At least two dated prices for the same store are needed.',
              ),
            ),
          for (final increase in increases)
            ListTile(
              isThreeLine: true,
              leading: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.deepOrange,
              ),
              title: Text(
                '${stores.where((s) => s.storeId == increase.current.storeId).firstOrNull?.storeName ?? 'Store ${increase.current.storeId}'}: +${AppFormatters.currency(increase.amount)}${increase.percent == null ? '' : ' (${increase.percent!.toStringAsFixed(1)}%)'}',
              ),
              subtitle: Text(
                'Recorded ${AppFormatters.dateTime(increase.current.recordedAt)}\n${AppFormatters.currency(increase.previous.price)} on ${AppFormatters.dateTime(increase.previous.recordedAt)} → ${AppFormatters.currency(increase.current.price)} / $unit',
              ),
            ),
          if (increases.isNotEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'The warning indicates an increase between recorded prices. It does not by itself indicate overpricing or a violation.',
              ),
            ),
        ],
      ),
    );
  }
}
