import 'package:flutter/material.dart';
import '../../db/repositories/customer_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/customer.dart';
import '../../widgets/textfield/textfield.dart';
import '../../widgets/textfield/date_field.dart';
import '../../widgets/button/button.dart';
import '../../widgets/card/form_section_card.dart';
import '../../utils/snackbar_utils.dart';

class AddCustomerPage extends StatefulWidget {
  const AddCustomerPage({super.key});

  @override
  State<AddCustomerPage> createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends State<AddCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _creditLimitController = TextEditingController();
  final _noteController = TextEditingController();
  final _customerRepo = CustomerRepository();

  DateTime? _nextDueDate;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _creditLimitController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final date = await showDatePicker(
      context: context,
      initialDate: _nextDueDate ??
          DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            datePickerTheme: theme.datePickerTheme.copyWith(
              backgroundColor: theme.colorScheme.surface,
              headerBackgroundColor: theme.colorScheme.primaryContainer,
              headerForegroundColor: theme.colorScheme.onPrimaryContainer,
              todayBackgroundColor: WidgetStateProperty.all(
                theme.colorScheme.primaryContainer,
              ),
              todayForegroundColor: WidgetStateProperty.all(
                theme.colorScheme.onPrimaryContainer,
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
            ),
          ),
          child: Directionality(
            textDirection: t.isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: child!,
          ),
        );
      },
    );
    if (date != null) {
      setState(() => _nextDueDate = date);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final id = 'cust_${DateTime.now().millisecondsSinceEpoch}';
    final customer = Customer(
      id: id,
      storeId: 'default_store',
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      creditLimit: _creditLimitController.text.trim().isEmpty
          ? null
          : double.tryParse(_creditLimitController.text.trim()),
      nextDueDate: _nextDueDate,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      status: CustomerStatus.active,
      createdAt: DateTime.now(),
    );

    await _customerRepo.insert(customer);

    if (!mounted) return;
    final t = AppLocalizations.of(context);
    showSuccessSnackBar(context, t.translate('customer_added'));
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.translate('new_customer')),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FormSectionCard(
                icon: Icons.person_outline,
                title: t.translate('customer_info'),
                child: Column(
                  children: [
                    AppTextField(
                      label: t.translate('customer_name'),
                      hintText: t.translate('enter_name'),
                      controller: _nameController,
                      prefixIcon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return t.translate('name_required');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: t.translate('notes'),
                      hintText: t.translate('enter_notes'),
                      controller: _noteController,
                      prefixIcon: Icons.notes_outlined,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              FormSectionCard(
                icon: Icons.contact_phone_outlined,
                title: t.translate('contact_info'),
                child: Column(
                  children: [
                    AppTextField(
                      label: t.translate('phone'),
                      hintText: t.translate('enter_phone'),
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_outlined,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: t.translate('address'),
                      hintText: t.translate('enter_address'),
                      controller: _addressController,
                      prefixIcon: Icons.location_on_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              FormSectionCard(
                icon: Icons.account_balance_wallet_outlined,
                title: t.translate('financial_info'),
                child: Column(
                  children: [
                    AppTextField(
                      label: t.translate('credit_limit'),
                      hintText: t.translate('enter_credit_limit'),
                      controller: _creditLimitController,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.monetization_on_outlined,
                      suffix: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            t.translate('dzd'),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppDateField(
                      label: t.translate('next_due_date'),
                      value: _nextDueDate,
                      onTap: _pickDate,
                      onClear: _nextDueDate != null
                          ? () => setState(() => _nextDueDate = null)
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              AppButton(
                label: t.translate('save'),
                loadingLabel: t.translate('saving'),
                icon: Icons.check_rounded,
                isLoading: _isSaving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
