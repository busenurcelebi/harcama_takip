import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../services/expense_storage.dart';
import 'add_expense_page.dart';

class ExpensesListPage extends StatefulWidget {
  const ExpensesListPage({super.key});

  @override
  State<ExpensesListPage> createState() => _ExpensesListPageState();
}

class _ExpensesListPageState extends State<ExpensesListPage> {
  final ExpenseStorage _storage = ExpenseStorage();
  List<Expense> _expenses = [];
  bool _isLoading = true;

  // Kategori filtresi
  final List<String> _filterCategories = const [
    'Hepsi',
    'Yemek',
    'Market',
    'Ulaşım',
    'Fatura',
    'Eğlence',
    'Diğer',
  ];
  String _selectedCategoryFilter = 'Hepsi';

  // Dönem filtresi
  final List<_PeriodFilter> _periodFilters = const [
    _PeriodFilter(_PeriodType.thisMonth, 'Bu Ay'),
    _PeriodFilter(_PeriodType.lastMonth, 'Geçen Ay'),
    _PeriodFilter(_PeriodType.last3Months, 'Son 3 Ay'),
    _PeriodFilter(_PeriodType.last6Months, 'Son 6 Ay'),
    _PeriodFilter(_PeriodType.thisYear, 'Bu Yıl'),
    _PeriodFilter(_PeriodType.allTime, 'Tüm Zamanlar'),
  ];
  _PeriodFilter _selectedPeriodFilter =
      const _PeriodFilter(_PeriodType.thisMonth, 'Bu Ay');

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final items = await _storage.loadExpenses();
    setState(() {
      _expenses = items;
      _isLoading = false;
    });
  }

  Future<void> _saveExpenses() async {
    await _storage.saveExpenses(_expenses);
  }

  void _addExpense(Expense expense) {
    setState(() => _expenses.add(expense));
    _saveExpenses();
  }

  void _deleteExpense(Expense expense) {
    setState(() => _expenses.removeWhere((e) => e.id == expense.id));
    _saveExpenses();
  }

  double get _totalAmount => _expenses.fold(0.0, (sum, e) => sum + e.amount);

  double get _thisMonthTotal {
    final now = DateTime.now();
    final thisMonth = _expenses.where(
      (e) => e.date.year == now.year && e.date.month == now.month,
    );
    return thisMonth.fold(0.0, (sum, e) => sum + e.amount);
  }

  double get _lastMonthTotal {
    final now = DateTime.now();
    final lastMonthDate = DateTime(now.year, now.month - 1, 1);
    final lastMonth = _expenses.where(
      (e) =>
          e.date.year == lastMonthDate.year &&
          e.date.month == lastMonthDate.month,
    );
    return lastMonth.fold(0.0, (sum, e) => sum + e.amount);
  }

  List<Expense> _applyPeriodFilter(List<Expense> input) {
    final range = _selectedPeriodFilter.range;
    if (range == null) return input;
    return input
        .where((e) =>
            !e.date.isBefore(range.start) && !e.date.isAfter(range.end))
        .toList();
  }

  List<Expense> get _filteredExpenses {
    final periodFiltered = _applyPeriodFilter(_expenses);
    if (_selectedCategoryFilter == 'Hepsi') return periodFiltered;
    return periodFiltered
        .where((e) => e.category == _selectedCategoryFilter)
        .toList();
  }

  Map<String, double> get _periodCategoryTotals {
    final inPeriod = _applyPeriodFilter(_expenses);

    final Map<String, double> totals = {
      for (final c in _filterCategories.where((c) => c != 'Hepsi')) c: 0.0,
    };

    for (final e in inPeriod) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }

    totals.removeWhere((_, v) => v <= 0);

    if (_selectedCategoryFilter != 'Hepsi') {
      final only = <String, double>{};
      final val = totals[_selectedCategoryFilter];
      if (val != null && val > 0) only[_selectedCategoryFilter] = val;
      return only;
    }

    return totals;
  }

  double get _filteredTotal =>
      _filteredExpenses.fold(0.0, (sum, e) => sum + e.amount);

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final dateFormatter = DateFormat('dd.MM.yyyy');
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Harcama Takip'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // ÖZET KART
                  Card(
                    elevation: 0,
                    color: cs.surfaceContainerHighest.withOpacity(0.55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cs.primary.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.pie_chart_rounded,
                              color: cs.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Toplam Harcama',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  formatter.format(_totalAmount),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 6,
                                  children: [
                                    _MiniChip(
                                      label: 'Bu ay: ${formatter.format(_thisMonthTotal)}',
                                    ),
                                    _MiniChip(
                                      label:
                                          'Geçen ay: ${formatter.format(_lastMonthTotal)}',
                                    ),
                                    _MiniChip(
                                      label:
                                          'Seçili filtre: ${formatter.format(_filteredTotal)}',
                                      emphasized: true,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // FİLTRE KARTI
                  Card(
                    elevation: 0,
                    color: cs.surfaceContainerHighest.withOpacity(0.55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _FilterDropdown<String>(
                              label: 'Kategori',
                              value: _selectedCategoryFilter,
                              items: _filterCategories,
                              onChanged: (val) {
                                if (val == null) return;
                                setState(() => _selectedCategoryFilter = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _FilterDropdown<_PeriodFilter>(
                              label: 'Dönem',
                              value: _selectedPeriodFilter,
                              items: _periodFilters,
                              itemLabel: (p) => p.label,
                              onChanged: (val) {
                                if (val == null) return;
                                setState(() => _selectedPeriodFilter = val);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // PASTA GRAFİK KARTI
                  Card(
                    elevation: 0,
                    color: cs.surfaceContainerHighest.withOpacity(0.55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_selectedPeriodFilter.label} Kategori Dağılımı',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _periodCategoryTotals.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 18),
                                  child: Text(
                                    'Bu dönemde pasta grafik oluşturacak veri yok.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 150,
                                      height: 150,
                                      child: _PieChart(
                                        data: _periodCategoryTotals,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _PieLegend(
                                        data: _periodCategoryTotals,
                                        formatter: formatter,
                                      ),
                                    ),
                                  ],
                                ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // LİSTE
                  Expanded(
                    child: _filteredExpenses.isEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 40,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Bu filtrede gösterilecek harcama yok.',
                                style: TextStyle(fontSize: 14),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Sağ alttan yeni harcama ekleyebilir veya filtreyi değiştirebilirsiniz.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            itemCount: _filteredExpenses.length,
                            itemBuilder: (context, index) {
                              final expense = _filteredExpenses[index];

                              return Card(
                                elevation: 0,
                                color: cs.surfaceContainerHighest
                                    .withOpacity(0.45),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                margin:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor:
                                            _CategoryColors.colorFor(
                                                    expense.category)
                                                .withOpacity(0.15),
                                        child: Text(
                                          expense.category.substring(0, 1),
                                          style: TextStyle(
                                            color: _CategoryColors.colorFor(
                                                expense.category),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              expense.category,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              dateFormatter.format(expense.date),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            if (expense.note != null) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                expense.note!,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            formatter.format(expense.amount),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          InkWell(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            onTap: () => _deleteExpense(expense),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(6.0),
                                              child: Icon(
                                                Icons.delete_outline,
                                                size: 20,
                                                color: cs.error,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddExpensePage(onSave: _addExpense),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final bool emphasized;
  const _MiniChip({required this.label, this.emphasized = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: emphasized ? cs.primary.withOpacity(0.10) : Colors.white70,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: emphasized ? cs.primary.withOpacity(0.25) : Colors.black12,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
          color: emphasized ? cs.primary : Colors.black87,
        ),
      ),
    );
  }
}

enum _PeriodType {
  thisMonth,
  lastMonth,
  last3Months,
  last6Months,
  thisYear,
  allTime,
}

class _PeriodFilter {
  final _PeriodType type;
  final String label;

  const _PeriodFilter(this.type, this.label);

  DateTimeRange? get range {
    final now = DateTime.now();

    DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
    DateTime endOfDay(DateTime d) =>
        DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

    switch (type) {
      case _PeriodType.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        final end = endOfDay(DateTime(now.year, now.month + 1, 0));
        return DateTimeRange(start: startOfDay(start), end: end);
      case _PeriodType.lastMonth:
        final prev = DateTime(now.year, now.month - 1, 1);
        final start = DateTime(prev.year, prev.month, 1);
        final end = endOfDay(DateTime(prev.year, prev.month + 1, 0));
        return DateTimeRange(start: startOfDay(start), end: end);
      case _PeriodType.last3Months:
        final start = DateTime(now.year, now.month - 2, 1);
        final end = endOfDay(DateTime(now.year, now.month + 1, 0));
        return DateTimeRange(start: startOfDay(start), end: end);
      case _PeriodType.last6Months:
        final start = DateTime(now.year, now.month - 5, 1);
        final end = endOfDay(DateTime(now.year, now.month + 1, 0));
        return DateTimeRange(start: startOfDay(start), end: end);
      case _PeriodType.thisYear:
        final start = DateTime(now.year, 1, 1);
        final end = endOfDay(DateTime(now.year, 12, 31));
        return DateTimeRange(start: startOfDay(start), end: end);
      case _PeriodType.allTime:
        return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _PeriodFilter &&
          runtimeType == other.runtimeType &&
          type == other.type;

  @override
  int get hashCode => type.hashCode;
}

class _FilterDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T)? itemLabel;
  final ValueChanged<T?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.itemLabel,
  });

  @override
  Widget build(BuildContext context) {
    final labelFn = itemLabel ?? (v) => v.toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.black12),
            ),
          ),
          items: items
              .map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Text(labelFn(c)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _PieLegend extends StatelessWidget {
  final Map<String, double> data;
  final NumberFormat formatter;

  const _PieLegend({
    required this.data,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final total = data.values.fold(0.0, (s, v) => s + v);
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _CategoryColors.colorFor(e.key),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    e.key,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Text(
                  formatter.format(e.value),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  total <= 0
                      ? '0%'
                      : '${((e.value / total) * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PieChart extends StatelessWidget {
  final Map<String, double> data;
  const _PieChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PiePainter(data),
      child: const SizedBox.expand(),
    );
  }
}

class _PiePainter extends CustomPainter {
  final Map<String, double> data;
  _PiePainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.values.fold(0.0, (s, v) => s + v);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 4;

    // Arka halka
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..color = Colors.black.withOpacity(0.06);
    canvas.drawCircle(center, radius, bgPaint);

    if (total <= 0) return;

    var startAngle = -math.pi / 2;
    for (final e in data.entries) {
      final sweep = (e.value / total) * 2 * math.pi;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round
        ..color = _CategoryColors.colorFor(e.key);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _PiePainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

class _CategoryColors {
  static Color colorFor(String category) {
    switch (category) {
      case 'Yemek':
        return Colors.green;
      case 'Market':
        return Colors.orange;
      case 'Ulaşım':
        return Colors.blue;
      case 'Fatura':
        return Colors.purple;
      case 'Eğlence':
        return Colors.red;
      case 'Diğer':
        return Colors.teal;
      default:
        // Hepsi / bilinmeyen
        return Colors.indigo;
    }
  }
}
