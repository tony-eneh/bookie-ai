import 'dart:async';

import 'package:bookie_ai/data/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:bookie_ai/data/providers/accounts_provider.dart';
import 'package:bookie_ai/data/providers/categories_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookie_ai/core/theme/app_colors.dart';
import 'package:bookie_ai/core/utils/date_formatter.dart';
import 'package:bookie_ai/data/models/transaction_model.dart';
import 'package:bookie_ai/data/providers/transactions_provider.dart';
import 'package:bookie_ai/widgets/shimmer_loading.dart';
import 'package:bookie_ai/features/home/widgets/transaction_tile.dart';
import 'package:bookie_ai/features/transactions/widgets/add_transaction_sheet.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  String _activeFilter = 'All';
  String _searchQuery = '';
  String? _accountId;
  String? _categoryId;
  Timer? _searchDebounce;

  static const _filters = [
    'All',
    'Income',
    'Expense',
    'This Week',
    'This Month',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(transactionsProvider.notifier).loadNextPage();
    }
  }

  void _applyFilter(String filter) {
    setState(() => _activeFilter = filter);
    _reload();
  }

  /// Rebuilds the server query from the chip, search box and filter sheet.
  void _reload() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final filters = TransactionFilters(
      type: switch (_activeFilter) {
        'Income' => 'INCOME',
        'Expense' => 'EXPENSE',
        _ => null,
      },
      startDate: switch (_activeFilter) {
        'This Week' => DateTime(weekStart.year, weekStart.month, weekStart.day),
        'This Month' => DateTime(now.year, now.month, 1),
        _ => null,
      },
      accountId: _accountId,
      categoryId: _categoryId,
      search: _searchQuery.isEmpty ? null : _searchQuery,
    );
    ref.read(transactionsProvider.notifier).fetchTransactions(filters: filters);
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      final q = value.trim();
      if (q == _searchQuery) return;
      setState(() => _searchQuery = q);
      _reload();
    });
  }

  int get _sheetFilterCount =>
      (_accountId != null ? 1 : 0) + (_categoryId != null ? 1 : 0);

  Future<void> _showFilterSheet() async {
    String? accountId = _accountId;
    String? categoryId = _categoryId;
    final apply = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final accounts = ref.watch(accountsProvider).valueOrNull ?? const [];
          final categories =
              ref.watch(categoriesProvider).valueOrNull ?? const [];
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Filter transactions',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  initialValue: accountId,
                  dropdownColor: AppColors.surface,
                  decoration: const InputDecoration(labelText: 'Account'),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('All accounts')),
                    for (final a in accounts)
                      DropdownMenuItem(value: a.id, child: Text(a.name)),
                  ],
                  onChanged: (v) => setSheet(() => accountId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: categoryId,
                  dropdownColor: AppColors.surface,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('All categories')),
                    for (final c in categories)
                      DropdownMenuItem(
                        value: c.id,
                        child: Text('${c.icon}  ${c.name}'),
                      ),
                  ],
                  onChanged: (v) => setSheet(() => categoryId = v),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          accountId = null;
                          categoryId = null;
                          Navigator.pop(ctx, true);
                        },
                        child: const Text('Clear'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
    if (apply != true) return;
    setState(() {
      _accountId = accountId;
      _categoryId = categoryId;
    });
    _reload();
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.primary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const AddTransactionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Transactions',
                      style: textTheme.headlineMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Filter',
                    icon: Badge(
                      isLabelVisible: _sheetFilterCount > 0,
                      label: Text('$_sheetFilterCount'),
                      backgroundColor: AppColors.accent,
                      child: Icon(
                        Icons.filter_list,
                        color: _sheetFilterCount > 0
                            ? AppColors.accent
                            : AppColors.textSecondary,
                      ),
                    ),
                    onPressed: _showFilterSheet,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search transactions...',
                  hintStyle: const TextStyle(color: AppColors.textTertiary),
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.textTertiary),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isActive = _activeFilter == filter;
                  return GestureDetector(
                    onTap: () => _applyFilter(filter),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.accent.withValues(alpha: 0.15)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive
                              ? AppColors.accent
                              : AppColors.surfaceBorder,
                        ),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: isActive
                              ? AppColors.accent
                              : AppColors.textSecondary,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w400,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: transactionsAsync.when(
                loading: () => const SingleChildScrollView(
                  child: _TransactionsShimmer(),
                ),
                error: (error, _) => _ErrorView(
                  message: friendlyError(error),
                  onRetry: () => ref
                      .read(transactionsProvider.notifier)
                      .fetchTransactions(),
                ),
                data: (paginated) {
                  final transactions = paginated.data;

                  if (transactions.isEmpty) {
                    return _EmptyState(onAdd: _showAddSheet);
                  }

                  return _GroupedTransactionList(
                    transactions: transactions,
                    scrollController: _scrollController,
                    hasMore: paginated.hasMore,
                    onRefresh: () async => ref
                        .read(transactionsProvider.notifier)
                        .fetchTransactions(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSheet,
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _GroupedTransactionList extends StatelessWidget {
  const _GroupedTransactionList({
    required this.transactions,
    required this.scrollController,
    required this.hasMore,
    required this.onRefresh,
  });

  final List<Transaction> transactions;
  final ScrollController scrollController;
  final bool hasMore;
  final Future<void> Function() onRefresh;

  Map<String, List<Transaction>> _groupByDate() {
    final grouped = <String, List<Transaction>>{};
    for (final tx in transactions) {
      final key = _dateGroupKey(tx.occurredAt);
      grouped.putIfAbsent(key, () => []).add(tx);
    }
    return grouped;
  }

  String _dateGroupKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(txDay).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormatter.fullDate(date);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final groups = _groupByDate();
    final groupKeys = groups.keys.toList();

    return RefreshIndicator(
      color: AppColors.accent,
      backgroundColor: AppColors.surface,
      onRefresh: onRefresh,
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: groupKeys.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == groupKeys.length) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            );
          }

          final key = groupKeys[index];
          final txList = groups[key]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (index > 0) const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  key,
                  style: textTheme.titleSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...txList.map((tx) => TransactionTile(transaction: tx)),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first transaction to get started',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Transaction'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionsShimmer extends StatelessWidget {
  const _TransactionsShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const ShimmerBox(width: 60, height: 14),
          const SizedBox(height: 12),
          ...List.generate(
            6,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  ShimmerBox(width: 44, height: 44, borderRadius: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: 120, height: 14),
                        SizedBox(height: 6),
                        ShimmerBox(width: 80, height: 10),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ShimmerBox(width: 72, height: 14),
                      SizedBox(height: 6),
                      ShimmerBox(width: 48, height: 10),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
