import 'package:bookie_ai/data/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:bookie_ai/core/theme/app_colors.dart';
import 'package:bookie_ai/data/models/category_model.dart';
import 'package:bookie_ai/data/models/transaction_model.dart';
import 'package:bookie_ai/data/providers/accounts_provider.dart';
import 'package:bookie_ai/data/providers/categories_provider.dart';
import 'package:bookie_ai/data/providers/transactions_provider.dart';

/// Adds a transaction, or edits [existing] when given.
class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({super.key, this.existing});

  final Transaction? existing;

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _noteController = TextEditingController();

  String _type = 'EXPENSE';
  String? _selectedCategoryId;
  String? _selectedAccountId;
  DateTime _selectedDate = DateTime.now();
  bool _showNotes = false;
  bool _isLoading = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    if (t != null) {
      _type = t.type == 'INCOME' ? 'INCOME' : 'EXPENSE';
      _amountController.text = t.amount.toStringAsFixed(
        t.amount.truncateToDouble() == t.amount ? 0 : 2,
      );
      _descriptionController.text = t.description ?? t.merchantName ?? '';
      _noteController.text = t.note ?? '';
      _showNotes = (t.note ?? '').isNotEmpty;
      _selectedCategoryId = t.categoryId;
      _selectedAccountId = t.accountId;
      _selectedDate = t.occurredAt.toLocal();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accent,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a description'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    if (_isEdit) {
      await _saveEdit(amount);
      return;
    }

    final accounts = ref.read(accountsProvider).valueOrNull ?? const [];
    final account =
        accounts.where((a) => a.id == _selectedAccountId).firstOrNull ??
            accounts.firstOrNull;
    if (account == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Add an account first, then record transactions in it.'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Keep the picked day but the current time, so "today" entries sort
      // correctly and don't shift to the previous day when sent as UTC.
      final now = DateTime.now();
      final occurredAt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        now.hour,
        now.minute,
        now.second,
      );

      await ref.read(transactionsProvider.notifier).createTransaction({
        'type': _type,
        'amount': amount,
        'currency': account.currency,
        'description': _descriptionController.text.trim(),
        'occurredAt': occurredAt.toUtc().toIso8601String(),
        'sourceType': 'MANUAL',
        if (_selectedCategoryId != null) 'categoryId': _selectedCategoryId,
        'accountId': account.id,
        if (_noteController.text.trim().isNotEmpty)
          'note': _noteController.text.trim(),
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add transaction: ${friendlyError(e)}'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveEdit(double amount) async {
    final existing = widget.existing!;
    setState(() => _isLoading = true);
    try {
      final local = existing.occurredAt.toLocal();
      final sameDay = local.year == _selectedDate.year &&
          local.month == _selectedDate.month &&
          local.day == _selectedDate.day;
      await ref.read(transactionsProvider.notifier).updateTransaction(
        existing.id,
        {
          'type': _type,
          'amount': amount,
          'description': _descriptionController.text.trim(),
          if (_selectedCategoryId != null) 'categoryId': _selectedCategoryId,
          'note': _noteController.text.trim(),
          if (!sameDay)
            'occurredAt': DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
              local.hour,
              local.minute,
            ).toUtc().toIso8601String(),
        },
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save: ${friendlyError(e)}'),
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
    final accountsAsync = ref.watch(accountsProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
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
              _isEdit ? 'Edit Transaction' : 'Add Transaction',
              style: textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            _TypeToggle(
              selected: _type,
              onChanged: (v) => setState(() => _type = v),
            ),
            const SizedBox(height: 24),
            Center(
              child: SizedBox(
                width: 200,
                child: TextField(
                  controller: _amountController,
                  style: textTheme.displayMedium?.copyWith(
                    color: _type == 'EXPENSE'
                        ? AppColors.expense
                        : AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: textTheme.displayMedium?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                ),
              ),
            ),
            Center(
              child: Text(
                widget.existing?.currency ??
                    accountsAsync.whenOrNull(
                      data: (accounts) {
                        final account = accounts
                            .where((a) => a.id == _selectedAccountId)
                            .firstOrNull;
                        return account?.currency;
                      },
                    ) ??
                    'USD',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _descriptionController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'e.g. Grocery shopping',
              ),
              textCapitalization: TextCapitalization.sentences,
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
              loading: () => const Center(
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (_, __) => Text(
                'Could not load categories',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              data: (categories) {
                final filtered =
                    categories.where((c) => c.type == _type).toList();
                return _CategoryGrid(
                  categories: filtered,
                  selectedId: _selectedCategoryId,
                  onSelected: (id) => setState(() => _selectedCategoryId = id),
                );
              },
            ),
            const SizedBox(height: 20),
            if (!_isEdit)
              accountsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (accounts) {
                  if (accounts.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet_outlined,
                              color: AppColors.warning),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'You need an account (bank, wallet or cash) to '
                              'record transactions in.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              final router = GoRouter.of(context);
                              Navigator.of(context).pop();
                              router.go('/accounts');
                            },
                            child: const Text('Add one'),
                          ),
                        ],
                      ),
                    );
                  }
                  _selectedAccountId ??=
                      accounts.where((a) => a.isPrimary).firstOrNull?.id ??
                          accounts.first.id;
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedAccountId,
                    decoration: const InputDecoration(labelText: 'Account'),
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: AppColors.textPrimary),
                    items: accounts.map((a) {
                      return DropdownMenuItem(
                        value: a.id,
                        child: Text(a.name),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedAccountId = v);
                    },
                  );
                },
              ),
            const SizedBox(height: 20),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  suffixIcon: Icon(Icons.calendar_today,
                      color: AppColors.textSecondary),
                ),
                child: Text(
                  DateFormat('MMM d, y').format(_selectedDate),
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => setState(() => _showNotes = !_showNotes),
              child: Row(
                children: [
                  Icon(
                    _showNotes ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Add notes',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (_showNotes) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Optional notes...',
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _isLoading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor:
                      _type == 'EXPENSE' ? AppColors.expense : AppColors.accent,
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
                    : Text(
                        _isEdit
                            ? 'Save changes'
                            : 'Add ${_type == 'EXPENSE' ? 'Expense' : 'Income'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _ToggleItem(
            label: 'Expense',
            isSelected: selected == 'EXPENSE',
            color: AppColors.expense,
            onTap: () => onChanged('EXPENSE'),
          ),
          _ToggleItem(
            label: 'Income',
            isSelected: selected == 'INCOME',
            color: AppColors.accent,
            onTap: () => onChanged('INCOME'),
          ),
        ],
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  const _ToggleItem({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color:
                isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? color : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Text(
        'No categories available',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textTertiary,
            ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        final selected = selectedId == cat.id;
        return GestureDetector(
          onTap: () => onSelected(cat.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.accent.withValues(alpha: 0.15)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? AppColors.accent : AppColors.surfaceBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(cat.icon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  cat.name,
                  style: TextStyle(
                    color:
                        selected ? AppColors.accent : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
