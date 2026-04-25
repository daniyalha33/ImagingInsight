// lib/screens/mobile/ai_report_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

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

class AIReportScreen extends StatefulWidget {
  final VoidCallback onBack;
  final Map<String, dynamic>? reportData;

  const AIReportScreen({
    Key? key,
    required this.onBack,
    this.reportData,
  }) : super(key: key);

  @override
  State<AIReportScreen> createState() => _AIReportScreenState();
}

class _AIReportScreenState extends State<AIReportScreen> {
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    final bool hasValidData = widget.reportData != null &&
        widget.reportData!.containsKey('organs') &&
        widget.reportData!['organs'] != null &&
        (widget.reportData!['organs'] as List).isNotEmpty;

    final organs = hasValidData
        ? (widget.reportData!['organs'] as List)
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

    final scanInfo = widget.reportData?['scan_info'];
    final summary = widget.reportData?['summary'];
    final aiFindings = widget.reportData?['ai_findings'] ?? '';
    final technicalDetails = widget.reportData?['technical_details'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(hasValidData),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReportHeaderCard(scanInfo),
                  const SizedBox(height: 16),
                  _buildSummaryStats(summary, organs),
                  const SizedBox(height: 20),
                  const Text(
                    'Segmented Organs',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E40AF),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...organs.map((organ) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildOrganCard(organ),
                      )),
                  const SizedBox(height: 8),
                  _buildAIFindings(hasValidData, aiFindings),
                  const SizedBox(height: 16),
                  _buildTechnicalDetails(hasValidData, technicalDetails),
                  const SizedBox(height: 16),
                  // Download button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isDownloading
                          ? null
                          : () => _downloadPDF(
                                context,
                                organs,
                                scanInfo,
                                summary,
                                aiFindings,
                                technicalDetails,
                              ),
                      icon: _isDownloading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            )
                          : const Icon(Icons.download),
                      label: Text(
                          _isDownloading ? 'Generating PDF…' : 'Download Report PDF'),
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
                  _buildDisclaimer(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── PDF generation & download ─────────────────────────────────────────────

  Future<void> _downloadPDF(
    BuildContext context,
    List<OrganData> organs,
    Map<String, dynamic>? scanInfo,
    Map<String, dynamic>? summary,
    String aiFindings,
    Map<String, dynamic>? technicalDetails,
  ) async {
    setState(() => _isDownloading = true);

    try {
      final pdf = pw.Document();

      // Load font (uses built-in Helvetica — no asset needed)
      final regularFont = pw.Font.helvetica();
      final boldFont = pw.Font.helveticaBold();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => _buildPdfHeader(boldFont, scanInfo),
          footer: (context) => _buildPdfFooter(regularFont, context),
          build: (context) => [
            _buildPdfSummarySection(boldFont, regularFont, summary, organs),
            pw.SizedBox(height: 20),
            _buildPdfOrgansTable(boldFont, regularFont, organs),
            pw.SizedBox(height: 20),
            if (aiFindings.isNotEmpty)
              _buildPdfFindingsSection(boldFont, regularFont, aiFindings),
            pw.SizedBox(height: 20),
            if (technicalDetails != null)
              _buildPdfTechnicalSection(boldFont, regularFont, technicalDetails),
            pw.SizedBox(height: 20),
            _buildPdfDisclaimer(regularFont),
          ],
        ),
      );

      final bytes = await pdf.save();

      // Save to downloads/documents folder
      final dir = Platform.isAndroid
          ? Directory('/storage/emulated/0/Download')
          : await getApplicationDocumentsDirectory();

      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final scanId = scanInfo?['scan_id'] ?? 'CT-Report';
      final date = DateTime.now();
      final filename =
          '${scanId}_${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}.pdf';
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);

      setState(() => _isDownloading = false);

      if (!mounted) return;

      // Show success dialog with share option
      _showDownloadSuccessDialog(context, file.path, bytes, filename);
    } catch (e) {
      setState(() => _isDownloading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate PDF: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _showDownloadSuccessDialog(
  BuildContext context,
  String filePath,
  Uint8List bytes,
  String filename,
) {
  // Stable copy so closures can't lose the reference
  final Uint8List stableBytes = Uint8List.fromList(bytes);

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade600),
          const SizedBox(width: 8),
          const Text('PDF Ready',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Saved to Downloads folder.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              filename,
              style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('OK'),
        ),
        // Preview
        ElevatedButton.icon(
          onPressed: () async {
            Navigator.pop(ctx);
            try {
              await Printing.layoutPdf(
                onLayout: (_) async => stableBytes,
                name: filename,
              );
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Preview failed: $e'),
                    backgroundColor: Colors.red.shade700,
                  ),
                );
              }
            }
          },
          icon: const Icon(Icons.visibility, size: 16),
          label: const Text('Preview'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        ),
        // Share
        ElevatedButton.icon(
          onPressed: () async {
            Navigator.pop(ctx);
            try {
              // Write to app cache — share_plus needs a cache path on Android
              final cacheDir = await getTemporaryDirectory();
              final cacheFile = File('${cacheDir.path}/$filename');
              await cacheFile.writeAsBytes(stableBytes);

              await Share.shareXFiles(
                [XFile(cacheFile.path, mimeType: 'application/pdf')],
                subject: 'CT Scan Report — $filename',
              );
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Share failed: $e'),
                    backgroundColor: Colors.red.shade700,
                  ),
                );
              }
            }
          },
          icon: const Icon(Icons.share, size: 16),
          label: const Text('Share'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2463EB),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    ),
  );
}
  // ── PDF builders ──────────────────────────────────────────────────────────

  pw.Widget _buildPdfHeader(pw.Font boldFont, Map<String, dynamic>? scanInfo) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.blue800, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('CT Scan Analysis Report',
                  style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 18,
                      color: PdfColors.blue800)),
              pw.SizedBox(height: 2),
              pw.Text(
                  'Generated: ${scanInfo?['date'] ?? DateTime.now().toString().substring(0, 10)}',
                  style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 10,
                      color: PdfColors.grey600)),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue800,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Text('AI Generated',
                style: pw.TextStyle(
                    font: boldFont, fontSize: 10, color: PdfColors.white)),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfFooter(pw.Font font, pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border:
            pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('CT Segmentation AI — For educational purposes only',
              style:
                  pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey500)),
          pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
              style:
                  pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey500)),
        ],
      ),
    );
  }

  pw.Widget _buildPdfSummarySection(
    pw.Font boldFont,
    pw.Font regularFont,
    Map<String, dynamic>? summary,
    List<OrganData> organs,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: _pdfStatBox(boldFont, regularFont, 'Organs Detected',
                '${summary?['organs_detected'] ?? organs.length}'),
          ),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: _pdfStatBox(boldFont, regularFont, 'Total Volume',
                summary?['total_volume'] ?? 'N/A'),
          ),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: _pdfStatBox(boldFont, regularFont, 'Abnormalities',
                '${summary?['abnormalities_count'] ?? 0}'),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfStatBox(
      pw.Font boldFont, pw.Font regularFont, String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(label,
            style: pw.TextStyle(
                font: regularFont, fontSize: 9, color: PdfColors.grey600)),
        pw.SizedBox(height: 4),
        pw.Text(value,
            style: pw.TextStyle(
                font: boldFont, fontSize: 16, color: PdfColors.blue800)),
      ],
    );
  }

  pw.Widget _buildPdfOrgansTable(
      pw.Font boldFont, pw.Font regularFont, List<OrganData> organs) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Segmented Organs',
            style: pw.TextStyle(
                font: boldFont, fontSize: 14, color: PdfColors.blue800)),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: ['Organ', 'Volume', 'Voxel Count', 'Status'],
          data: organs
              .map((o) => [o.name, o.volume, o.voxels, o.status])
              .toList(),
          headerStyle: pw.TextStyle(
              font: boldFont, fontSize: 10, color: PdfColors.white),
          headerDecoration:
              const pw.BoxDecoration(color: PdfColors.blue800),
          cellStyle: pw.TextStyle(font: regularFont, fontSize: 10),
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.center,
            2: pw.Alignment.center,
            3: pw.Alignment.center,
          },
          oddRowDecoration:
              const pw.BoxDecoration(color: PdfColors.grey100),
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
        ),
      ],
    );
  }

  pw.Widget _buildPdfFindingsSection(
      pw.Font boldFont, pw.Font regularFont, String aiFindings) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Text('AI Findings',
                style: pw.TextStyle(
                    font: boldFont, fontSize: 14, color: PdfColors.blue800)),
            pw.SizedBox(width: 8),
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue700,
                borderRadius:
                    const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text('Gemini AI',
                  style: pw.TextStyle(
                      font: boldFont, fontSize: 8, color: PdfColors.white)),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            borderRadius:
                const pw.BorderRadius.all(pw.Radius.circular(8)),
            border: pw.Border.all(color: PdfColors.blue200),
          ),
          child: pw.Text(
            aiFindings,
            style: pw.TextStyle(
                font: regularFont,
                fontSize: 10,
                lineSpacing: 4,
                color: PdfColors.grey800),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPdfTechnicalSection(
    pw.Font boldFont,
    pw.Font regularFont,
    Map<String, dynamic> technicalDetails,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Technical Details',
            style: pw.TextStyle(
                font: boldFont, fontSize: 14, color: PdfColors.blue800)),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius:
                const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            children: [
              _pdfTechRow(boldFont, regularFont, 'Model',
                  technicalDetails['model_name'] ?? 'N/A'),
              pw.Divider(color: PdfColors.grey200),
              _pdfTechRow(boldFont, regularFont, 'Processing Time',
                  technicalDetails['processing_time'] ?? 'N/A'),
              if (technicalDetails['ai_model'] != null) ...[
                pw.Divider(color: PdfColors.grey200),
                _pdfTechRow(boldFont, regularFont, 'AI Model',
                    technicalDetails['ai_model']),
              ],
              if (technicalDetails['voxel_spacing'] != null) ...[
                pw.Divider(color: PdfColors.grey200),
                _pdfTechRow(
                    boldFont,
                    regularFont,
                    'Voxel Spacing',
                    (technicalDetails['voxel_spacing'] as List)
                        .map((v) => v.toString())
                        .join(' × ')),
              ],
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _pdfTechRow(
      pw.Font boldFont, pw.Font regularFont, String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  font: regularFont, fontSize: 10, color: PdfColors.grey600)),
          pw.Text(value,
              style: pw.TextStyle(
                  font: boldFont, fontSize: 10, color: PdfColors.grey800)),
        ],
      ),
    );
  }

  pw.Widget _buildPdfDisclaimer(pw.Font regularFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.amber50,
        border: pw.Border.all(color: PdfColors.amber200),
        borderRadius:
            const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Text(
        '⚠ DISCLAIMER: This AI-generated report is for educational and research purposes only. '
        'It should not be used as a substitute for professional medical diagnosis. '
        'Always consult a qualified radiologist for clinical interpretation.',
        style: pw.TextStyle(
            font: regularFont, fontSize: 9, color: PdfColors.amber900),
      ),
    );
  }

  // ── Flutter UI builders ───────────────────────────────────────────────────

  Widget _buildHeader(bool hasValidData) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.blue.shade100)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
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
              if (!hasValidData)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    );
  }

  Widget _buildReportHeaderCard(Map<String, dynamic>? scanInfo) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2463EB), Color(0xFF1E40AF)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CT Scan Analysis',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  SizedBox(height: 4),
                  Text('Patient Scan Report',
                      style:
                          TextStyle(fontSize: 14, color: Colors.white70)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('AI Generated',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
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
                    const Text('Date',
                        style: TextStyle(
                            fontSize: 12, color: Colors.white70)),
                    const SizedBox(height: 4),
                    Text(scanInfo?['date'] ?? 'N/A',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Scan ID',
                        style: TextStyle(
                            fontSize: 12, color: Colors.white70)),
                    const SizedBox(height: 4),
                    Text(scanInfo?['scan_id'] ?? 'N/A',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats(
      Map<String, dynamic>? summary, List<OrganData> organs) {
    return Row(
      children: [
        Expanded(
          child: _statCard('Organs Detected',
              '${summary?['organs_detected'] ?? organs.length}'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
              'Total Volume', summary?['total_volume'] ?? 'N/A'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard('Abnormalities',
              '${summary?['abnormalities_count'] ?? 0}',
              highlight: (summary?['abnormalities_count'] ?? 0) > 0),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value,
      {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: highlight
                ? Colors.orange.shade200
                : Colors.blue.shade100),
      ),
      child: Column(
        children: [
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: highlight
                    ? Colors.orange.shade700
                    : const Color(0xFF1E40AF),
              )),
        ],
      ),
    );
  }

  Widget _buildOrganCard(OrganData organ) {
    return Container(
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
                child: Text(organ.name,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E40AF))),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: organ.statusBgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(organ.status,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: organ.statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Volume',
                        style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B))),
                    const SizedBox(height: 4),
                    Text(organ.volume,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E40AF))),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Voxel Count',
                        style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B))),
                    const SizedBox(height: 4),
                    Text(organ.voxels,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E40AF))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAIFindings(bool hasValidData, String aiFindings) {
    return Container(
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
              const Text('AI Findings',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E40AF))),
              const SizedBox(width: 8),
              if (hasValidData && aiFindings.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2463EB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Gemini AI',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            aiFindings.isNotEmpty
                ? aiFindings
                : 'No AI findings available.',
            style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1E293B),
                height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalDetails(
      bool hasValidData, Map<String, dynamic>? technicalDetails) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Technical Details',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E40AF))),
          const SizedBox(height: 12),
          _buildTechnicalRow('Model',
              technicalDetails?['model_name'] ?? 'UNet3D-BTCV v3.2'),
          const SizedBox(height: 8),
          _buildTechnicalRow('Processing Time',
              technicalDetails?['processing_time'] ?? 'N/A'),
          if (hasValidData && technicalDetails?['ai_model'] != null) ...[
            const SizedBox(height: 8),
            _buildTechnicalRow(
                'AI Model', technicalDetails!['ai_model']),
          ],
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        border: Border.all(color: const Color(0xFFFDE68A)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('⚠️', style: TextStyle(fontSize: 16)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'This AI-generated report is for educational purposes. '
              'Always consult with a qualified radiologist for clinical diagnosis.',
              style: TextStyle(fontSize: 13, color: Color(0xFFA16207)),
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
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: Color(0xFF64748B))),
        Flexible(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B)),
              textAlign: TextAlign.right),
        ),
      ],
    );
  }

  // ── Utilities ─────────────────────────────────────────────────────────────

  Color _parseColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return Colors.grey;
    try {
      return Color(int.parse('FF${colorHex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
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
          statusBgColor: const Color(0xFFD1FAE5)),
      OrganData(
          name: 'Kidney (Left)',
          color: const Color(0xFF3B82F6),
          volume: '156 cm³',
          voxels: '234,567',
          status: 'Normal Size',
          statusColor: const Color(0xFF059669),
          statusBgColor: const Color(0xFFD1FAE5)),
      OrganData(
          name: 'Kidney (Right)',
          color: const Color(0xFF22C55E),
          volume: '148 cm³',
          voxels: '221,890',
          status: 'Normal Size',
          statusColor: const Color(0xFF059669),
          statusBgColor: const Color(0xFFD1FAE5)),
      OrganData(
          name: 'Spleen',
          color: const Color(0xFFF59E0B),
          volume: '215 cm³',
          voxels: '345,123',
          status: 'Normal Size',
          statusColor: const Color(0xFF059669),
          statusBgColor: const Color(0xFFD1FAE5)),
      OrganData(
          name: 'Pancreas',
          color: const Color(0xFF9333EA),
          volume: '82 cm³',
          voxels: '125,678',
          status: 'Normal Size',
          statusColor: const Color(0xFF059669),
          statusBgColor: const Color(0xFFD1FAE5)),
    ];
  }
}