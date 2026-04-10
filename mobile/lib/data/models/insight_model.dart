import 'package:bookie_ai/core/utils/json_parsers.dart';
import 'package:bookie_ai/data/models/transaction_model.dart';

class DashboardData {
  final double totalIncome;
  final double totalExpenses;
  final double netCashFlow;
  final List<BudgetProgress> budgetProgress;
  final List<CategoryBreakdown> topCategories;
  final List<GoalProgress> goalProgress;
  final int pendingClarifications;
  final List<Transaction> recentTransactions;
  final List<String> insights;

  const DashboardData({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netCashFlow,
    required this.budgetProgress,
    required this.topCategories,
    required this.goalProgress,
    required this.pendingClarifications,
    required this.recentTransactions,
    required this.insights,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      totalIncome: parseDouble(json['totalIncome']),
      totalExpenses: parseDouble(json['totalExpenses']),
      netCashFlow: parseDouble(json['netCashFlow']),
      budgetProgress: (json['budgetProgress'] as List<dynamic>?)
              ?.map((e) =>
                  BudgetProgress.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      topCategories: (json['topCategories'] as List<dynamic>?)
              ?.map((e) =>
                  CategoryBreakdown.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      goalProgress: (json['goalProgress'] as List<dynamic>?)
              ?.map((e) =>
                  GoalProgress.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pendingClarifications:
          json['pendingClarifications'] as int? ?? 0,
      recentTransactions: (json['recentTransactions'] as List<dynamic>?)
              ?.map((e) =>
                  Transaction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      insights: (json['insights'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'netCashFlow': netCashFlow,
      'budgetProgress':
          budgetProgress.map((e) => e.toJson()).toList(),
      'topCategories':
          topCategories.map((e) => e.toJson()).toList(),
      'goalProgress': goalProgress.map((e) => e.toJson()).toList(),
      'pendingClarifications': pendingClarifications,
      'recentTransactions':
          recentTransactions.map((e) => e.toJson()).toList(),
      'insights': insights,
    };
  }

  @override
  String toString() =>
      'DashboardData(income: $totalIncome, expenses: $totalExpenses, net: $netCashFlow)';
}

class BudgetProgress {
  final String name;
  final double amount;
  final double used;
  final double percentage;

  const BudgetProgress({
    required this.name,
    required this.amount,
    required this.used,
    required this.percentage,
  });

  factory BudgetProgress.fromJson(Map<String, dynamic> json) {
    return BudgetProgress(
      name: json['name'] as String,
      amount: parseDouble(json['amount']),
      used: parseDouble(json['used']),
      percentage: parseDouble(json['percentage']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'used': used,
      'percentage': percentage,
    };
  }

  @override
  String toString() =>
      'BudgetProgress(name: $name, used: $used/$amount)';
}

class CategoryBreakdown {
  final String name;
  final String icon;
  final double amount;
  final int count;

  const CategoryBreakdown({
    required this.name,
    required this.icon,
    required this.amount,
    required this.count,
  });

  factory CategoryBreakdown.fromJson(Map<String, dynamic> json) {
    return CategoryBreakdown(
      name: json['name'] as String,
      icon: json['icon'] as String? ?? '📦',
      amount: parseDouble(json['amount']),
      count: json['count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': icon,
      'amount': amount,
      'count': count,
    };
  }

  @override
  String toString() =>
      'CategoryBreakdown(name: $name, amount: $amount, count: $count)';
}

class GoalProgress {
  final String title;
  final double targetAmount;
  final double currentAmount;
  final double percentage;
  final String status;

  const GoalProgress({
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.percentage,
    required this.status,
  });

  factory GoalProgress.fromJson(Map<String, dynamic> json) {
    return GoalProgress(
      title: json['title'] as String,
      targetAmount: parseDouble(json['targetAmount']),
      currentAmount: parseDouble(json['currentAmount']),
      percentage: parseDouble(json['percentage']),
      status: json['status'] as String? ?? 'ON_TRACK',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'percentage': percentage,
      'status': status,
    };
  }

  @override
  String toString() =>
      'GoalProgress(title: $title, $currentAmount/$targetAmount)';
}

class WeeklySummary {
  final double totalIncome;
  final double totalExpenses;
  final double netCashFlow;
  final double incomeChange;
  final double expenseChange;
  final List<CategoryBreakdown> topCategories;
  final int pendingClarifications;

  const WeeklySummary({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netCashFlow,
    required this.incomeChange,
    required this.expenseChange,
    required this.topCategories,
    required this.pendingClarifications,
  });

  factory WeeklySummary.fromJson(Map<String, dynamic> json) {
    return WeeklySummary(
      totalIncome: parseDouble(json['totalIncome']),
      totalExpenses: parseDouble(json['totalExpenses']),
      netCashFlow: parseDouble(json['netCashFlow']),
      incomeChange: parseDouble(json['incomeChange']),
      expenseChange: parseDouble(json['expenseChange']),
      topCategories: (json['topCategories'] as List<dynamic>?)
              ?.map((e) =>
                  CategoryBreakdown.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pendingClarifications:
          json['pendingClarifications'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'netCashFlow': netCashFlow,
      'incomeChange': incomeChange,
      'expenseChange': expenseChange,
      'topCategories':
          topCategories.map((e) => e.toJson()).toList(),
      'pendingClarifications': pendingClarifications,
    };
  }

  @override
  String toString() =>
      'WeeklySummary(income: $totalIncome, expenses: $totalExpenses, net: $netCashFlow)';
}
