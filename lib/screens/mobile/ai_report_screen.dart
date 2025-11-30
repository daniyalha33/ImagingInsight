// lib/screens/mobile/ai_report_screen.dart
import 'package:flutter/material.dart';

class OrganData {
  final String name;
  final Color color;
  final String volume;
  final String voxels;
  final String status;
  final Color statusColor;
  final Color statusBgColor;

  OrganData({
    required this.name,
    required this.color,
    required this.volume,
    required this.voxels,
    required this.status,
    required this.statusColor,
    required this.statusBgColor,
  });
}

class AIReportScreen extends StatelessWidget {
  final VoidCallback onBack;
  final Map<String, dynamic>? reportData;

  const AIReportScreen({
    Key? key,
    required this.onBack,
    this.reportData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: Check if reportData exists and has organs
    final bool hasValidData = reportData != null && 
                               reportData!.containsKey('organs') && 
                               reportData!['organs'] != null &&
                               (reportData!['organs'] as List).isNotEmpty;

    // ✅ Parse API data or use dummy data as fallback
    final organs = hasValidData
        ? (reportData!['organs'] as List)
            .map((organ) => OrganData(
                  name: organ['name'] ?? 'Unknown',
                  color: _parseColor(organ['color']),
                  volume: organ['volume'] ?? 'N/A',
                  voxels: organ['voxels'] ?? 'N/A',
                  status: organ['status'] ?? 'Unknown',
                  statusColor: _parseColor(organ['status_color']),
                  statusBgColor: _parseColor(organ['status_bg_color']),
                ))
            .toList()
        : _getDummyOrganData();

    final scanInfo = reportData?['scan_info'];
    final summary = reportData?['summary'];
    final aiFindings = reportData?['ai_findings'] ?? '';
    final technicalDetails = reportData?['technical_details'];

    // ✅ Debug print to verify data
    print('🔍 AIReportScreen Debug:');
    print('   Has valid data: $hasValidData');
    print('   Organs count: ${organs.length}');
    print('   AI findings length: ${aiFindings.length}');
    print('   Scan info: $scanInfo');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.blue.shade100),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back),
                      color: const Color(0xFF1E40AF),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'AI Analysis Report',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                    const Spacer(),
                    // ✅ Show indicator if using dummy data
                    if (!hasValidData)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Demo Data',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFEA580C),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Report Header Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2463EB), Color(0xFF1E40AF)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Abdomen CT Analysis',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Patient Scan Report',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'AI Generated',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Date',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    scanInfo?['date'] ?? 'Oct 11, 2025',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Scan ID',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    scanInfo?['scan_id'] ?? 'ABS-001-2025',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Summary Stats
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Organs Detected',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${summary?['organs_detected'] ?? organs.length}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E40AF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Total Volume',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                summary?['total_volume'] ?? '2,057 cm³',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E40AF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Segmented Organs Title
                  const Text(
                    'Segmented Organs',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E40AF),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Organ Details Cards
                  ...organs.map((organ) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: organ.color,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      organ.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E40AF),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: organ.statusBgColor,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      organ.status,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: organ.statusColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Volume',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          organ.volume,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1E40AF),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Voxel Count',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          organ.voxels,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1E40AF),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )),

                  const SizedBox(height: 8),

                  // AI Findings
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'AI Findings',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E40AF),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // ✅ Show Gemini badge if real data
                            if (hasValidData && aiFindings.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2463EB),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Gemini AI',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          aiFindings.isNotEmpty 
                              ? aiFindings 
                              : 'No AI findings available. Run segmentation and generate report first.',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1E293B),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Technical Details
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Technical Details',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildTechnicalRow(
                          'Model Name', 
                          technicalDetails?['model_name'] ?? 'UNet3D-BTCV v3.2'
                        ),
                        const SizedBox(height: 8),
                        _buildTechnicalRow(
                          'Processing Time', 
                          technicalDetails?['processing_time'] ?? 'N/A'
                        ),
                        if (hasValidData && technicalDetails?['ai_model'] != null) ...[
                          const SizedBox(height: 8),
                          _buildTechnicalRow(
                            'AI Model', 
                            technicalDetails!['ai_model']
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Download Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement PDF download
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('PDF download feature coming soon!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Download Report PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2463EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Disclaimer
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⚠️',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This AI-generated report is for educational purposes. Always consult with a qualified radiologist for clinical diagnosis.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFFA16207),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Color _parseColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return Colors.grey;
    
    try {
      // Remove # if present
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  List<OrganData> _getDummyOrganData() {
    return [
      OrganData(
        name: 'Liver',
        color: const Color(0xFFEF4444),
        volume: '1,456 cm³',
        voxels: '2,345,678',
        status: 'Normal Size',
        statusColor: const Color(0xFF059669),
        statusBgColor: const Color(0xFFD1FAE5),
      ),
      OrganData(
        name: 'Kidney (Left)',
        color: const Color(0xFF3B82F6),
        volume: '156 cm³',
        voxels: '234,567',
        status: 'Normal Size',
        statusColor: const Color(0xFF059669),
        statusBgColor: const Color(0xFFD1FAE5),
      ),
      OrganData(
        name: 'Kidney (Right)',
        color: const Color(0xFF22C55E),
        volume: '148 cm³',
        voxels: '221,890',
        status: 'Normal Size',
        statusColor: const Color(0xFF059669),
        statusBgColor: const Color(0xFFD1FAE5),
      ),
      OrganData(
        name: 'Spleen',
        color: const Color(0xFFF59E0B),
        volume: '215 cm³',
        voxels: '345,123',
        status: 'Normal Size',
        statusColor: const Color(0xFF059669),
        statusBgColor: const Color(0xFFD1FAE5),
      ),
      OrganData(
        name: 'Pancreas',
        color: const Color(0xFF9333EA),
        volume: '82 cm³',
        voxels: '125,678',
        status: 'Normal Size',
        statusColor: const Color(0xFF059669),
        statusBgColor: const Color(0xFFD1FAE5),
      ),
    ];
  }
}