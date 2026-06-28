import 'package:flutter/material.dart';
import '../../db/repositories/store_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/store.dart';

class StoreDetailsPage extends StatefulWidget {
  final String storeId;

  const StoreDetailsPage({super.key, required this.storeId});

  @override
  State<StoreDetailsPage> createState() => _StoreDetailsPageState();
}

class _StoreDetailsPageState extends State<StoreDetailsPage> {
  final StoreRepository _repo = StoreRepository();
  Store? _store;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final store = await _repo.getById(widget.storeId);
    if (!mounted) return;
    setState(() {
      _store = store;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.translate('store_details')),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _store == null
              ? Center(child: Text(t.translate('no_customers')))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                          width: 0.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.store_outlined,
                              size: 40,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _store!.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _infoRow(
                            Icons.location_on_outlined,
                            t.translate('address'),
                            _store!.address,
                            theme,
                          ),
                          const SizedBox(height: 12),
                          _infoRow(
                            Icons.phone_outlined,
                            t.translate('phone'),
                            _store!.phone,
                            theme,
                          ),
                          const SizedBox(height: 12),
                          _infoRow(
                            Icons.monetization_on_outlined,
                            t.translate('currency'),
                            _store!.currency,
                            theme,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _infoRow(
      IconData icon, String label, String value, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            Text(value, style: theme.textTheme.bodyMedium),
          ],
        ),
      ],
    );
  }
}
