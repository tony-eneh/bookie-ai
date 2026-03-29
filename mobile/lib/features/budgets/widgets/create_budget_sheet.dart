import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookie_ai/core/constants/app_constants.dart';
import 'package:bookie_ai/core/theme/app_colors.dart';
import 'package:bookie_ai/core/utils/date_formatter.dart';
import 'package:bookie_ai/data/models/category_model.dart';
import 'package:bookie_ai/data/providers/budgets_provider.dart';
import 'package:bookie_ai/data/providers/categories_provider.dart';

class CreateBudgetSheet extends ConsumerStatefulWidget {
  const CreateBudgetSheet({super.key});

  @override
  ConsumerState<CreateBudgetSheet> createState() => _CreateBudgetSheetState();
}

class _CreateBudgetSheetState extends ConsumerState<CreateBudgetSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  String _periodType = 'MONTHLY';
  String _selectedCurrency = 'USD';
  String? _selectedCategoryId;
  DateTime _startDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(budgetsProvider.notifier).createBudget({
        'name': _nameController.text.trim(),
        if (_selectedCategoryId != null) 'categoryId': _selectedCategoryId,
        'periodType': _periodType,
        'amount': double.parse(_amountController.text),
        'currency': _selectedCurrency,
        'startDate': _startDate.toIso8601String(),
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create budget: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final categoriesAsync = ref.watch(categoriesProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'New Budget',
                style: textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Budget Name',
                  hintText: 'e.g. Groceries, Entertainment',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 20),

              Text(
                'Category',
                style: textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              categoriesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => Text(
                  'Could not load categories',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.expense,
                  ),
                ),
                data: (categories) => _CategorySelector(
                  categories: categories,
                  selectedId: _selectedCategoryId,
                  onSelected: (id) =>
                      setState(() => _selectedCategoryId = id),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Period',
                style: textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: ['WEEKLY', 'MONTHLY'].map((type) {
                  final selected = _periodType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(type),
                      selected: selected,
                      onSelected: (_) =>
                          setState(() => _periodType = type),
                      selectedColor:
                          AppColors.accent.withValues(alpha: 0.2),
                      backgroundColor: AppColors.surface,
                      labelStyle: TextStyle(
                        color: selected
                            ? AppColors.accent
                            : AppColors.textSecondary,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 13,
                      ),
                      side: BorderSide(
                        color: selected
                            ? AppColors.accent
                            : AppColors.surfaceBorder,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: _selectedCurrency,
                decoration: const InputDecoration(labelText: 'Currency'),
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: AppColors.textPrimary),
                items: AppConstants.supportedCurrencies.map((c) {
                  final symbol = AppConstants.currencySymbols[c] ?? c;
                  return DropdownMenuItem(
                    value: c,
                    child: Text('$symbol  $c'),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedCurrency = v);
                },
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _amountController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Budget Amount',
                  prefixText:
                      '${AppConstants.currencySymbols[_selectedCurrency] ?? _selectedCurrency} ',
                  prefixStyle:
                      const TextStyle(color: AppColors.textSecondary),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Amount is required';
                  final amount = double.tryParse(v);
                  if (amount == null || amount <= 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              GestureDetector(
                onTap: _pickStartDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Start Date',
                    suffixIcon:
                        Icon(Icons.calendar_today, size: 18),
                  ),
                  child: Text(
                    DateFormatter.fullDate(_startDate),
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Create Budget',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        final selected = selectedId == cat.id;
        return ChoiceChip(
          label: Text('${cat.icon} ${cat.name}'),
          selected: selected,
          onSelected: (_) =>
              onSelected(selected ? null : cat.id),
          selectedColor: AppColors.accent.withValues(alpha: 0.2),
          backgroundColor: AppColors.surface,
          labelStyle: TextStyle(
            color:
                selected ? AppColors.accent : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
          side: BorderSide(
            color: selected ? AppColors.accent : AppColors.surfaceBorder,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        );
      }).toList(),
    );
  }
}
