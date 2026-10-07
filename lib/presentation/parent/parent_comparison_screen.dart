import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/student_comparison_result.dart';
import '../../state/api_provider.dart';
import '../../state/parent_provider.dart';

class ParentComparisonScreen extends ConsumerStatefulWidget {
  const ParentComparisonScreen({super.key});

  @override
  ConsumerState<ParentComparisonScreen> createState() => _ParentComparisonScreenState();
}

class _ParentComparisonScreenState extends ConsumerState<ParentComparisonScreen> {
  final Set<String> _selectedForComparison = {};
  List<StudentComparisonResult>? _comparisonResults;
  bool _isLoading = false;
  String? _errorMessage;

  void _runComparison() async {
    if (_selectedForComparison.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least 2 children to compare.'), backgroundColor: AppTheme.late),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(apiServiceProvider);
      final results = await api.parentCompareChildrenAttendance(_selectedForComparison.toList());
      setState(() {
        _isLoading = false;
        _comparisonResults = results;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final childrenAsync = ref.watch(parentChildrenProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Child Attendance Comparison'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Compare Attendance Across Children',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Select two or more linked children to generate an authoritative backend comparative analysis.',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  childrenAsync.when(
                    data: (children) {
                      if (children.length < 2) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(8)),
                          child: const Text(
                            'Comparison is available when 2 or more children are linked to your account.',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                        );
                      }

                      return Column(
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: children.map((c) {
                              final sId = c['studentId'] as String;
                              final isSelected = _selectedForComparison.contains(sId);

                              return FilterChip(
                                label: Text('${c['name']} (${c['className']})'),
                                selected: isSelected,
                                selectedColor: AppTheme.primary.withAlpha(30),
                                checkmarkColor: AppTheme.primary,
                                onSelected: (val) {
                                  setState(() {
                                    if (val) {
                                      _selectedForComparison.add(sId);
                                    } else {
                                      _selectedForComparison.remove(sId);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: _isLoading
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.analytics_outlined, size: 18),
                            label: const Text('Generate Comparison Report'),
                            onPressed: _isLoading ? null : _runComparison,
                          ),
                        ],
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Error loading children: $e'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (_errorMessage != null) ...[
            Card(
              color: AppTheme.absentLight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error: $_errorMessage', style: const TextStyle(color: AppTheme.absent)),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Comparison Results
          if (_comparisonResults != null) ...[
            const Text('Comparison Results (Authoritative Backend Data)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            LayoutBuilder(builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? 2 : 1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isWide ? 1.4 : 1.3,
                ),
                itemCount: _comparisonResults!.length,
                itemBuilder: (context, index) {
                  final res = _comparisonResults![index];
                  final percent = res.attendancePercentage;
                  final isGood = percent >= 75.0;

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(res.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                  Text(res.className, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isGood ? AppTheme.presentLight : AppTheme.lateLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${percent.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: isGood ? const Color(0xFF047857) : const Color(0xFFB45309),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(color: AppTheme.cardBorder),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _statCol('Present', '${res.presentCount}', AppTheme.present),
                              _statCol('Late', '${res.lateCount}', AppTheme.late),
                              _statCol('Absent', '${res.absentCount}', AppTheme.absent),
                              _statCol('Total', '${res.totalSessions}', AppTheme.textPrimary),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _statCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }
}
