import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../state/parent_provider.dart';

class ParentTutorInfoScreen extends ConsumerWidget {
  const ParentTutorInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tutorsAsync = ref.watch(parentTutorInfoProvider);
    final childrenAsync = ref.watch(parentChildrenProvider);
    final selectedChildId = ref.watch(parentSelectedChildIdProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Tutor Contact Information'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Child Selector
          childrenAsync.when(
            data: (children) {
              if (children.isEmpty) return const SizedBox.shrink();
              return Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const Text(
                        'Child: ',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedChildId ?? children.first['studentId'],
                            isExpanded: true,
                            items: children.map((c) {
                              return DropdownMenuItem(
                                value: c['studentId'] as String,
                                child: Text(
                                  '${c['name']} (${c['className']})',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                              );
                            }).toList(),
                            onChanged: (newId) {
                              if (newId != null) {
                                ref.read(parentSelectedChildIdProvider.notifier).select(newId);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),

          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Authorized Tutors for Selected Class',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'Tutor contact details are provided for reference. Parents may reach out independently.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ),

          tutorsAsync.when(
            data: (tutors) {
              if (tutors.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: const [
                          Icon(Icons.person_off_rounded, size: 40, color: AppTheme.textMuted),
                          SizedBox(height: 12),
                          Text('No Authorized Tutors Listed', style: TextStyle(fontWeight: FontWeight.w600)),
                          SizedBox(height: 4),
                          Text('Contact your tuition administration for details.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tutors.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final t = tutors[index];

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFF06B6D4).withAlpha(25),
                            child: Text(
                              t.name.isNotEmpty ? t.name[0].toUpperCase() : 'T',
                              style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                const SizedBox(height: 4),
                                if (t.currentPosition.isNotEmpty || t.currentSchool.isNotEmpty) ...[
                                  Text(
                                    '${t.currentPosition}${t.currentPosition.isNotEmpty && t.currentSchool.isNotEmpty ? ' at ' : ''}${t.currentSchool}',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                  ),
                                  const SizedBox(height: 6),
                                ],
                                // Phone number displayed as plain text (NO call/WhatsApp button per Section 20)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.background,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppTheme.cardBorder),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.phone_iphone_rounded, size: 16, color: AppTheme.textSecondary),
                                      const SizedBox(width: 6),
                                      Text(
                                        t.mobileNumber,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                                      ),
                                    ],
                                  ),
                                ),
                                if (t.specializedSubjects.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 4,
                                    children: t.specializedSubjects.map((s) {
                                      return Chip(
                                        label: Text(s, style: const TextStyle(fontSize: 10)),
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
            error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppTheme.absent))),
          ),
        ],
      ),
    );
  }
}
