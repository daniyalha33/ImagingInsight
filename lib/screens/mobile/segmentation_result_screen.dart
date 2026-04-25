// lib/screens/mobile/segmentation_result_screen.dart

import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import '../../services/api_service.dart';
import 'segmentation_quiz_screen.dart' show CaseResult;

class SegmentationResultScreen extends StatefulWidget {
  final String testId;
  final String testTitle;
  final List<CaseResult> caseResults;
  final Map<String, dynamic> overallData;
  final VoidCallback onBack;

  const SegmentationResultScreen({
    Key? key,
    required this.testId,
    required this.testTitle,
    required this.caseResults,
    required this.overallData,
    required this.onBack,
  }) : super(key: key);

  @override
  State<SegmentationResultScreen> createState() => _SegmentationResultScreenState();
}

class _SegmentationResultScreenState extends State<SegmentationResultScreen> {
  int _selectedCaseTab = 0;
  bool _showGroundTruth = false;
  ui.Image? _groundTruthImage;
  bool _gtLoading = false;

  Future<void> _loadGroundTruth(int caseIndex) async {
    setState(() { _gtLoading = true; _groundTruthImage = null; });
    try {
      final bytes = await ApiService.getSegmentationGroundTruth(
        testId:    widget.testId,
        caseIndex: caseIndex,
      );
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (mounted) setState(() { _groundTruthImage = frame.image; _gtLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _gtLoading = false);
    }
  }

  Color _gradeColor(String? grade) {
    switch (grade) {
      case 'A': return Colors.green;
      case 'B': return Colors.lightGreen;
      case 'C': return Colors.orange;
      case 'D': return Colors.deepOrange;
      default:  return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final overall     = widget.overallData;
    final overallGrade = overall['overallGrade'] as String? ?? 'F';
    final overallScore = (overall['overallScore'] as num?)?.toDouble() ?? 0;
    final attempted    = (overall['casesAttempted'] as num?)?.toInt() ?? 0;
    final total        = (overall['casesTotal'] as num?)?.toInt() ?? widget.caseResults.length;

    final attempted_results = widget.caseResults.where((r) => r.attempted).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            // Guard against setState after dispose
            if (mounted) widget.onBack();
          },
        ),
        title: const Text('Test Results'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E40AF),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.blue.shade100),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [

          // ── Overall Grade Card ────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_gradeColor(overallGrade).withOpacity(0.15), Colors.white],
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _gradeColor(overallGrade).withOpacity(0.4)),
            ),
            child: Column(children: [
              Text(
                overallGrade,
                style: TextStyle(
                  fontSize: 64, fontWeight: FontWeight.bold,
                  color: _gradeColor(overallGrade),
                ),
              ),
              Text(
                '${overallScore.toStringAsFixed(1)}% avg Dice score',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 4),
              Text(
                '$attempted / $total cases attempted',
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
            ]),
          ),

          const SizedBox(height: 16),

          // ── Aggregate metrics ────────────────────────────────────────────
          if (attempted_results.isNotEmpty) ...[
            Row(children: [
              _MetricCard(
                title: 'Avg Dice',
                value: attempted_results.map((r) => r.diceScore ?? 0).reduce((a, b) => a + b) / attempted_results.length,
                icon: Icons.center_focus_strong, color: const Color(0xFF2563EB),
              ),
              const SizedBox(width: 8),
              _MetricCard(
                title: 'Avg IoU',
                value: attempted_results.map((r) => r.iouScore ?? 0).reduce((a, b) => a + b) / attempted_results.length,
                icon: Icons.all_inclusive, color: Colors.purple,
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              _MetricCard(
                title: 'Avg Precision',
                value: attempted_results.map((r) => r.precision ?? 0).reduce((a, b) => a + b) / attempted_results.length,
                icon: Icons.gps_fixed, color: Colors.green,
              ),
              const SizedBox(width: 8),
              _MetricCard(
                title: 'Avg Recall',
                value: attempted_results.map((r) => r.recall ?? 0).reduce((a, b) => a + b) / attempted_results.length,
                icon: Icons.check_circle, color: Colors.orange,
              ),
            ]),
          ],

          const SizedBox(height: 16),

          // ── Per-Case breakdown ───────────────────────────────────────────
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.blue.shade100)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Per-Case Results',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
                const SizedBox(height: 12),

                // Case tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: List.generate(widget.caseResults.length, (i) {
                    final active = i == _selectedCaseTab;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() { _selectedCaseTab = i; _showGroundTruth = false; _groundTruthImage = null; });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: active ? const Color(0xFF2563EB) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('Case ${i + 1}',
                            style: TextStyle(color: active ? Colors.white : const Color(0xFF64748B),
                              fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    );
                  })),
                ),

                const SizedBox(height: 16),
                _buildCaseDetail(widget.caseResults[_selectedCaseTab], _selectedCaseTab),
              ]),
            ),
          ),

          const SizedBox(height: 16),

          // ── Ground Truth ─────────────────────────────────────────────────
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.blue.shade100)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Ground Truth',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
                  Switch(
                    value: _showGroundTruth,
                    activeColor: const Color(0xFF2563EB),
                    onChanged: (val) {
                      setState(() => _showGroundTruth = val);
                      if (val) _loadGroundTruth(_selectedCaseTab);
                    },
                  ),
                ]),
                if (_showGroundTruth) ...[
                  const SizedBox(height: 12),
                  _gtLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
                      : _groundTruthImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: RawImage(image: _groundTruthImage, fit: BoxFit.contain),
                            )
                          : const Text('Failed to load ground truth',
                              style: TextStyle(color: Color(0xFF94A3B8))),
                ],
              ]),
            ),
          ),

          const SizedBox(height: 24),

          // ── Actions ──────────────────────────────────────────────────────
          ElevatedButton.icon(
            onPressed: widget.onBack, 
            icon: const Icon(Icons.home),
            label: const Text('Back to Dashboard'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildCaseDetail(CaseResult r, int idx) {
    if (!r.attempted) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
        child: const Row(children: [
          Icon(Icons.cancel_outlined, color: Colors.grey),
          SizedBox(width: 8),
          Text('This case was not attempted', style: TextStyle(color: Color(0xFF64748B))),
        ]),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Grade badge
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _gradeColor(r.grade).withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('${r.grade ?? "?"}',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _gradeColor(r.grade))),
        ),
        const SizedBox(width: 16),
        Text('${r.diceScore?.toStringAsFixed(1) ?? "—"}% Dice',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ]),

      const SizedBox(height: 12),

      // Metrics grid
      Row(children: [
        _SmallMetric(label: 'IoU',       value: r.iouScore),
        const SizedBox(width: 8),
        _SmallMetric(label: 'Precision', value: r.precision),
        const SizedBox(width: 8),
        _SmallMetric(label: 'Recall',    value: r.recall),
      ]),

      const SizedBox(height: 12),

      // Feedback
      ...r.feedback.map((f) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('• ', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
            Expanded(child: Text(f, style: const TextStyle(fontSize: 14, color: Color(0xFF334155)))),
          ]))),
    ]);
  }
}

// ─── Small widgets ────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final String  title;
  final double  value;
  final IconData icon;
  final Color   color;

  const _MetricCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(child: Card(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.blue.shade50)),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(children: [
        Icon(icon, size: 28, color: color),
        const SizedBox(height: 6),
        Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)), textAlign: TextAlign.center),
        const SizedBox(height: 2),
        Text('${value.toStringAsFixed(1)}%',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ]),
    ),
  ));
}

class _SmallMetric extends StatelessWidget {
  final String  label;
  final double? value;
  const _SmallMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
    child: Column(children: [
      Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
      const SizedBox(height: 2),
      Text(
        value != null ? '${value!.toStringAsFixed(1)}%' : '—',
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
      ),
    ]),
  ));
}