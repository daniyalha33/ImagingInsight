// lib/screens/mobile/ai_segmentation_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

class AISegmentationScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onGenerateReport;
  final VoidCallback onBack;
  const AISegmentationScreen({
    Key? key,
    required this.onGenerateReport,
    required this.onBack,
  }) : super(key: key);

  @override
  State<AISegmentationScreen> createState() => _AISegmentationScreenState();
}

class _AISegmentationScreenState extends State<AISegmentationScreen> {
  // Backend configuration - UPDATE THIS WITH YOUR NGROK URL!
  final String backendUrl = 'https://fungous-physiognomically-herta.ngrok-free.dev';

  // State variables
  bool _uploadedFile = false;
  bool _isProcessing = false;
  bool _isSegmenting = false;
  bool _segmentationComplete = false;
  String _activeView = 'axial';
  int _currentSliceIndex = 0;

  // ── Engine tracking ───────────────────────────────────────────────────────
  // 'unet'             → .nii    → /process-ct        + /segment           + /generate-report
  // 'totalsegmentator' → .nii.gz → /process-ct-totalseg (combined)         + /generate-report-totalseg
  // 'mri'              → .nii/.nii.gz → /process-mri  + /segment-mri       + /generate-report-mri
  String _engine = 'unet';

  // CT / MRI data
  String? _filename;
  List<int>? _shape;
  List<double>? _voxelSizes;
  List<String> _axialSlices = [];
  List<String> _coronalSlices = [];
  List<String> _sagittalSlices = [];

  // Slice dimensions for each view
  Map<String, List<int>>? _sliceDimensions;

  // Segmentation slices
  List<String> _segmentationAxialSlices = [];
  List<String> _segmentationCoronalSlices = [];
  List<String> _segmentationSagittalSlices = [];

  // Segmentation data
  List<String> _segmentationSlices = [];
  Map<String, dynamic>? _segmentationAnalysis;
  int _organsFound = 0;

  // Error handling
  String? _errorMessage;
  bool _isGeneratingReport = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _errorMessage != null
                ? _buildErrorView()
                : (_uploadedFile ? _buildCTViewer() : _buildUploadSection()),
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader() {
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF2463EB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'AI Segmentation',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E40AF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Error view ──────────────────────────────────────────────────────────

  Widget _buildErrorView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade700),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.red.shade900),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                  _uploadedFile = false;
                  _isProcessing = false;
                  _isSegmenting = false;
                  _segmentationComplete = false;
                  _engine = 'unet';
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Upload section ──────────────────────────────────────────────────────

  Widget _buildUploadSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCEAFE),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Icon(Icons.upload_file, size: 40, color: Color(0xFF2463EB)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Upload Medical Scan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E40AF),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Upload CT or MRI scan in NIFTI format\n'
                  '• CT .nii → UNet3D segmentation\n'
                  '• CT .nii.gz → TotalSegmentator (117 organs)\n'
                  '• MRI .nii / .nii.gz → Brain segmentation',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _pickAndUploadFile,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.upload_file),
                    label: Text(_isProcessing ? 'Uploading...' : 'Select NIFTI File'),
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
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildInstructions(),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
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
              Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              const Text(
                'Instructions',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E40AF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInstructionItem('You will be asked to select CT or MRI after choosing a file'),
          _buildInstructionItem('.nii CT files → UNet3D model (upload + separate segment step)'),
          _buildInstructionItem('.nii.gz CT files → TotalSegmentator (upload + segment in one step)'),
          _buildInstructionItem('MRI files → Brain segmentation (upload + separate segment step)'),
          _buildInstructionItem('View slices in axial, coronal, and sagittal planes'),
          _buildInstructionItem('View segmented organs/structures with color overlay'),
          _buildInstructionItem('Generate detailed AI analysis report'),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
          ),
        ],
      ),
    );
  }

  // ── CT / MRI viewer ─────────────────────────────────────────────────────

  Widget _buildCTViewer() {
    if (_isProcessing) return _buildProcessingIndicator();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildFileInfo(),
          const SizedBox(height: 16),
          if (_segmentationComplete) _buildSegmentationStats(),
          if (_segmentationComplete) const SizedBox(height: 16),
          _buildViewTabs(),
          const SizedBox(height: 16),
          _buildSliceNavigator(),
          const SizedBox(height: 16),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildProcessingIndicator() {
    final String title = _isSegmenting
        ? (_engine == 'mri' ? 'Running Brain Segmentation' : 'Running AI Segmentation')
        : 'Processing Scan';

    final String subtitle = _isSegmenting
        ? (_engine == 'mri'
            ? 'SynthSeg running on GPU…'
            : _engine == 'totalsegmentator'
                ? 'TotalSegmentator running on GPU…'
                : 'UNet3D GPU processing on Colab…')
        : 'Uploading to backend…';

    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2463EB)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E40AF),
              ),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentationStats() {
    if (_segmentationAnalysis == null) return const SizedBox.shrink();

    // Engine badge colour
    Color badgeBg;
    Color badgeBorder;
    Color badgeText;
    String engineLabel;

    switch (_engine) {
      case 'totalsegmentator':
        badgeBg = Colors.purple.shade50;
        badgeBorder = Colors.purple.shade200;
        badgeText = Colors.purple.shade700;
        engineLabel = 'TotalSegmentator';
        break;
      case 'mri':
        badgeBg = Colors.teal.shade50;
        badgeBorder = Colors.teal.shade200;
        badgeText = Colors.teal.shade700;
        engineLabel = 'Brain MRI';
        break;
      default:
        badgeBg = Colors.blue.shade50;
        badgeBorder = Colors.blue.shade200;
        badgeText = Colors.blue.shade700;
        engineLabel = 'UNet3D';
    }

    final String foundLabel = _engine == 'mri'
        ? 'Found $_organsFound brain structures'
        : 'Found $_organsFound organs';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Segmentation Complete',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: badgeBorder),
                ),
                child: Text(
                  engineLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: badgeText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            foundLabel,
            style: TextStyle(fontSize: 14, color: Colors.green.shade900),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _segmentationAnalysis!.keys.map((key) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Text(
                  key.toString().replaceAll('_', ' '),
                  style: TextStyle(fontSize: 11, color: Colors.green.shade900),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFileInfo() {
    Color engineBg;
    Color engineBorder;
    Color engineText;
    String engineChip;

    switch (_engine) {
      case 'totalsegmentator':
        engineBg = Colors.purple.shade50;
        engineBorder = Colors.purple.shade200;
        engineText = Colors.purple.shade700;
        engineChip = 'TotalSeg';
        break;
      case 'mri':
        engineBg = Colors.teal.shade50;
        engineBorder = Colors.teal.shade200;
        engineText = Colors.teal.shade700;
        engineChip = 'Brain MRI';
        break;
      default:
        engineBg = Colors.blue.shade50;
        engineBorder = Colors.blue.shade200;
        engineText = Colors.blue.shade700;
        engineChip = 'UNet3D';
    }

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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image, size: 20, color: Color(0xFF059669)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _filename ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E40AF),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _shape != null
                          ? 'Shape: ${_shape![0]} × ${_shape![1]} × ${_shape![2]}'
                          : 'Processing…',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: engineBg,
                  border: Border.all(color: engineBorder),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  engineChip,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: engineText,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Uploaded',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),
          if (_voxelSizes != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoChip('Axial', '${_axialSlices.length} slices'),
                _buildInfoChip('Coronal', '${_coronalSlices.length} slices'),
                _buildInfoChip('Sagittal', '${_sagittalSlices.length} slices'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E40AF),
          ),
        ),
      ],
    );
  }

  // ── View tabs ───────────────────────────────────────────────────────────

  Widget _buildViewTabs() {
    final String viewTitle = _engine == 'mri' ? 'MRI Scan Views' : 'CT Scan Views';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              viewTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E40AF),
              ),
            ),
            if (_segmentationComplete)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.visibility, size: 12, color: Colors.purple.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'With Segmentation',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              _buildTabButton('Axial', 'axial'),
              _buildTabButton('Coronal', 'coronal'),
              _buildTabButton('Sagittal', 'sagittal'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildCTSliceView(),
      ],
    );
  }

  Widget _buildTabButton(String label, String value) {
    final bool isActive = _activeView == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeView = value;
            _currentSliceIndex = 0;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? const Color(0xFF2463EB) : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCTSliceView() {
    final List<String> displaySlices = _getDisplaySlices();

    if (displaySlices.isEmpty) {
      return Container(
        height: 300,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: const Text('No slices available'),
      );
    }

    final String base64Image = displaySlices[_currentSliceIndex];

    double aspectRatio = 1.0;
    if (_sliceDimensions != null && _sliceDimensions!.containsKey(_activeView)) {
      final dims = _sliceDimensions![_activeView]!;
      final int h = dims[0];
      final int w = dims[1];
      aspectRatio = w / h;
      if ((_activeView == 'sagittal' || _activeView == 'coronal') && h > w) {
        aspectRatio = 1.2;
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: aspectRatio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                base64Decode(base64Image),
                fit: BoxFit.fill,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${_activeView.toUpperCase()} View — '
            'Slice ${_currentSliceIndex + 1}/${displaySlices.length}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E40AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliceNavigator() {
    final List<String> displaySlices = _getDisplaySlices();
    if (displaySlices.isEmpty) return const SizedBox.shrink();

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
          const Text(
            'Navigate Slices',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E40AF),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: _currentSliceIndex > 0
                    ? () => setState(() => _currentSliceIndex--)
                    : null,
                icon: const Icon(Icons.chevron_left),
                color: const Color(0xFF2463EB),
              ),
              Expanded(
                child: Slider(
                  value: _currentSliceIndex.toDouble(),
                  min: 0,
                  max: (displaySlices.length - 1).toDouble(),
                  divisions: displaySlices.length - 1,
                  activeColor: const Color(0xFF2463EB),
                  onChanged: (value) {
                    setState(() => _currentSliceIndex = value.toInt());
                  },
                ),
              ),
              IconButton(
                onPressed: _currentSliceIndex < displaySlices.length - 1
                    ? () => setState(() => _currentSliceIndex++)
                    : null,
                icon: const Icon(Icons.chevron_right),
                color: const Color(0xFF2463EB),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Action buttons ──────────────────────────────────────────────────────

  Widget _buildActionButtons() {
    // UNet3D and MRI both need a separate segmentation step
    final bool needsSegmentStep =
        !_segmentationComplete && (_engine == 'unet' || _engine == 'mri');

    Color segButtonColor;
    String segButtonLabel;
    if (_engine == 'mri') {
      segButtonColor = const Color(0xFF0D9488); // teal
      segButtonLabel = _isSegmenting ? 'Running AI…' : 'Run Brain Segmentation';
    } else {
      segButtonColor = const Color(0xFF2463EB); // blue
      segButtonLabel = _isSegmenting ? 'Running AI…' : 'Run AI Segmentation';
    }

    return Column(
      children: [
        if (needsSegmentStep) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSegmenting
                  ? null
                  : (_engine == 'mri' ? _runMRISegmentation : _runSegmentation),
              icon: _isSegmenting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(segButtonLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: segButtonColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
        if (_segmentationComplete) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGeneratingReport ? null : _generateAIReport,
              icon: _isGeneratingReport
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.description),
              label: Text(_isGeneratingReport ? 'Generating…' : 'Generate AI Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  /// Returns the correct slice list for the current view + segmentation state.
  List<String> _getDisplaySlices() {
    if (_segmentationComplete) {
      switch (_activeView) {
        case 'coronal':
          return _segmentationCoronalSlices;
        case 'sagittal':
          return _segmentationSagittalSlices;
        default:
          return _segmentationAxialSlices;
      }
    }
    return _getCurrentSlices();
  }

  List<String> _getCurrentSlices() {
    switch (_activeView) {
      case 'coronal':
        return _coronalSlices;
      case 'sagittal':
        return _sagittalSlices;
      default:
        return _axialSlices;
    }
  }

  // ── Network calls ────────────────────────────────────────────────────────

  Future<void> _pickAndUploadFile() async {
    try {
      print('📁 Opening file picker…');

      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result == null || result.files.single.path == null) {
        print('❌ No file selected');
        return;
      }

      final String selectedFileName = result.files.single.name;
      print('📋 Selected file: $selectedFileName');

      // ── Ask user: CT or MRI? ─────────────────────────────────────────────
      if (!mounted) return;
      final String? modality = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Select Scan Type'),
          content: const Text('What type of scan are you uploading?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'ct'),
              child: const Text('CT Scan'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'mri'),
              child: const Text(
                'MRI Scan',
                style: TextStyle(color: Color(0xFF0D9488)),
              ),
            ),
          ],
        ),
      );

      if (modality == null) return; // user dismissed dialog

      // ── Route to correct endpoint ─────────────────────────────────────────
      String endpoint;
      String engineLabel;

      if (modality == 'mri') {
        endpoint = '/process-mri';
        engineLabel = 'mri';
      } else {
        // CT — pick engine based on extension
        final bool isTotalSeg = selectedFileName.endsWith('.nii.gz');
        endpoint = isTotalSeg ? '/process-ct-totalseg' : '/process-ct';
        engineLabel = isTotalSeg ? 'totalsegmentator' : 'unet';
      }

      setState(() {
        _isProcessing = true;
        _errorMessage = null;
        _engine = engineLabel;
      });

      print('🚀 Uploading to: $backendUrl$endpoint  (engine: $_engine)');

      final request = http.MultipartRequest('POST', Uri.parse('$backendUrl$endpoint'));
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          result.files.single.path!,
          filename: selectedFileName,
        ),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 10),
        onTimeout: () => throw Exception('Upload / processing timeout — check internet connection'),
      );

      final response = await http.Response.fromStream(streamedResponse);
      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (_engine == 'mri') {
          _applyMRIUploadResponse(data);
        } else if (_engine == 'totalsegmentator') {
          _applyTotalSegResponse(data);
        } else {
          _applyUNetUploadResponse(data);
        }
      } else {
        throw Exception('Server error: ${response.statusCode}\n${response.body}');
      }
    } catch (e) {
      print('❌ Upload failed: $e');
      setState(() {
        _errorMessage = 'Failed to upload scan: $e\n\n'
            'Check:\n'
            '- Colab server is running\n'
            '- ngrok URL is correct\n'
            '- Internet connection is stable';
        _isProcessing = false;
        _uploadedFile = false;
      });
    }
  }

  /// Populate state after a successful MRI upload response.
  void _applyMRIUploadResponse(Map<String, dynamic> data) {
    setState(() {
      _filename = data['filename'] as String?;
      _shape = (data['shape'] as List<dynamic>).cast<int>();
      _voxelSizes = (data['voxel_sizes'] as List<dynamic>).cast<double>();
      _sliceDimensions = {
        'axial':    (data['slice_dimensions']['axial']    as List<dynamic>).cast<int>(),
        'coronal':  (data['slice_dimensions']['coronal']  as List<dynamic>).cast<int>(),
        'sagittal': (data['slice_dimensions']['sagittal'] as List<dynamic>).cast<int>(),
      };
      _axialSlices    = (data['axial']    as List<dynamic>).cast<String>();
      _coronalSlices  = (data['coronal']  as List<dynamic>).cast<String>();
      _sagittalSlices = (data['sagittal'] as List<dynamic>).cast<String>();
      _uploadedFile      = true;
      _isProcessing      = false;
      _currentSliceIndex = 0;
    });

    print('✅ MRI uploaded — sequence: ${data['mri_sequence']}');
  }

  /// Populate state after a successful TotalSegmentator upload+segment response.
  void _applyTotalSegResponse(Map<String, dynamic> data) {
    final slices = data['segmentation_slices'] as Map<String, dynamic>;
    final dims   = data['slice_dimensions']    as Map<String, dynamic>;

    final List<dynamic> organList = data['organs'] as List<dynamic>? ?? [];
    final Map<String, dynamic> analysisMap = {
      for (final o in organList) (o['organ_key'] as String): o,
    };

    setState(() {
      _filename    = data['filename']    as String?;
      _shape       = (data['shape']       as List<dynamic>).cast<int>();
      _voxelSizes  = (data['voxel_sizes'] as List<dynamic>).cast<double>();
      _sliceDimensions = {
        'axial':    (dims['axial']    as List<dynamic>).cast<int>(),
        'coronal':  (dims['coronal']  as List<dynamic>).cast<int>(),
        'sagittal': (dims['sagittal'] as List<dynamic>).cast<int>(),
      };

      _axialSlices    = (slices['axial']    as List<dynamic>).cast<String>();
      _coronalSlices  = (slices['coronal']  as List<dynamic>).cast<String>();
      _sagittalSlices = (slices['sagittal'] as List<dynamic>).cast<String>();

      _segmentationAxialSlices    = _axialSlices;
      _segmentationCoronalSlices  = _coronalSlices;
      _segmentationSagittalSlices = _sagittalSlices;

      _segmentationAnalysis = analysisMap;
      _organsFound          = data['organs_found'] as int? ?? organList.length;
      _segmentationComplete = true;
      _uploadedFile         = true;
      _isProcessing         = false;
      _currentSliceIndex    = 0;
      _activeView           = 'axial';
    });

    print('✅ TotalSegmentator upload+segment complete — $_organsFound organs found');
  }

  /// Populate state after a plain UNet3D upload response (no segmentation yet).
  void _applyUNetUploadResponse(Map<String, dynamic> data) {
    setState(() {
      _filename   = data['filename']   as String?;
      _shape      = (data['shape']      as List<dynamic>).cast<int>();
      _voxelSizes = (data['voxel_sizes'] as List<dynamic>).cast<double>();
      _sliceDimensions = {
        'axial':    (data['slice_dimensions']['axial']    as List<dynamic>).cast<int>(),
        'coronal':  (data['slice_dimensions']['coronal']  as List<dynamic>).cast<int>(),
        'sagittal': (data['slice_dimensions']['sagittal'] as List<dynamic>).cast<int>(),
      };
      _axialSlices    = (data['axial']    as List<dynamic>).cast<String>();
      _coronalSlices  = (data['coronal']  as List<dynamic>).cast<String>();
      _sagittalSlices = (data['sagittal'] as List<dynamic>).cast<String>();
      _uploadedFile      = true;
      _isProcessing      = false;
      _currentSliceIndex = 0;
    });

    print('✅ UNet3D CT scan uploaded successfully');
  }

  /// Run UNet3D segmentation as a separate step (only used for .nii CT files).
  Future<void> _runSegmentation() async {
    try {
      print('🔬 Starting UNet3D AI segmentation on Colab GPU…');

      setState(() {
        _isSegmenting = true;
        _errorMessage = null;
      });

      final response = await http.post(
        Uri.parse('$backendUrl/segment'),
      ).timeout(
        const Duration(minutes: 10),
        onTimeout: () => throw Exception('Segmentation timeout — processing large CT scan'),
      );

      print('📥 Segmentation response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data      = jsonDecode(response.body) as Map<String, dynamic>;
        final segSlices = data['segmentation_slices'] as Map<String, dynamic>;

        print('✅ Segmentation complete! Organs found: ${data['organs_found']}');

        setState(() {
          _segmentationAxialSlices    = (segSlices['axial']    as List<dynamic>).cast<String>();
          _segmentationCoronalSlices  = (segSlices['coronal']  as List<dynamic>).cast<String>();
          _segmentationSagittalSlices = (segSlices['sagittal'] as List<dynamic>).cast<String>();
          _segmentationAnalysis       = Map<String, dynamic>.from(data['analysis'] as Map);
          _organsFound                = data['organs_found'] as int;
          _segmentationComplete       = true;
          _isSegmenting               = false;
          _currentSliceIndex          = 0;
          _activeView                 = 'axial';
        });
      } else {
        throw Exception('Segmentation failed: ${response.statusCode}\n${response.body}');
      }
    } catch (e) {
      print('❌ Segmentation error: $e');
      setState(() {
        _errorMessage = 'AI Segmentation failed: $e\n\n'
            'This may take several minutes for large scans.';
        _isSegmenting = false;
      });
    }
  }

  /// Run MRI brain segmentation as a separate step.
  Future<void> _runMRISegmentation() async {
    try {
      print('🧠 Starting MRI brain segmentation on GPU…');

      setState(() {
        _isSegmenting = true;
        _errorMessage = null;
      });

      final response = await http.post(
        Uri.parse('$backendUrl/segment-mri'),
      ).timeout(
        const Duration(minutes: 15),
        onTimeout: () => throw Exception('MRI segmentation timeout — brain segmentation can take longer'),
      );

      print('📥 MRI segmentation response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data           = jsonDecode(response.body) as Map<String, dynamic>;
        final segSlices      = data['segmentation_slices'] as Map<String, dynamic>;
        final List<dynamic> structureList = data['structures'] as List<dynamic>? ?? [];

        print('✅ MRI segmentation done — ${data['structures_found']} brain structures found');

        setState(() {
          _segmentationAxialSlices    = (segSlices['axial']    as List<dynamic>).cast<String>();
          _segmentationCoronalSlices  = (segSlices['coronal']  as List<dynamic>).cast<String>();
          _segmentationSagittalSlices = (segSlices['sagittal'] as List<dynamic>).cast<String>();
          _segmentationAnalysis = {
            for (final s in structureList)
              (s['structure_key'] as String): s,
          };
          _organsFound          = data['structures_found'] as int? ?? structureList.length;
          _segmentationComplete = true;
          _isSegmenting         = false;
          _currentSliceIndex    = 0;
          _activeView           = 'axial';
        });
      } else {
        throw Exception('MRI segmentation failed: ${response.statusCode}\n${response.body}');
      }
    } catch (e) {
      print('❌ MRI segmentation error: $e');
      setState(() {
        _errorMessage = 'MRI Segmentation failed: $e\n\n'
            'This may take several minutes for large brain scans.';
        _isSegmenting = false;
      });
    }
  }

  /// Generate the AI report. Automatically picks the right endpoint based on engine.
  Future<void> _generateAIReport() async {
    try {
      print('📊 Generating AI report (engine: $_engine)…');

      setState(() {
        _isGeneratingReport = true;
        _errorMessage       = null;
      });

      final String reportEndpoint = _engine == 'totalsegmentator'
          ? '/generate-report-totalseg'
          : _engine == 'mri'
              ? '/generate-report-mri'
              : '/generate-report';

      print('🚀 Calling: $backendUrl$reportEndpoint');

      final response = await http.post(
        Uri.parse('$backendUrl$reportEndpoint'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      ).timeout(
        const Duration(minutes: 3),
        onTimeout: () => throw Exception(
          'Report generation is taking longer than expected.\n\n'
          'This can happen with:\n'
          '• Slow Gemini API response\n'
          '• Network connectivity issues\n'
          '• Complex segmentation results\n\n'
          'Try again in a moment.',
        ),
      );

      print('📥 Report response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final reportData = jsonDecode(response.body) as Map<String, dynamic>;

        // Both CT and MRI reports must contain an 'organs' or 'structures' key
        final bool hasOrgans     = reportData.containsKey('organs');
        final bool hasStructures = reportData.containsKey('structures');

        if (!hasOrgans && !hasStructures) {
          throw Exception('Invalid report data received from server');
        }

        final int count = (reportData['organs'] ?? reportData['structures'])?.length ?? 0;
        print('✅ Report generated — $count entries');

        setState(() => _isGeneratingReport = false);
        widget.onGenerateReport(reportData);
      } else if (response.statusCode == 400) {
        throw Exception(
          'Segmentation not complete.\n\n'
          'Please run segmentation first before generating the report.',
        );
      } else if (response.statusCode == 503) {
        throw Exception(
          'Model not loaded on server.\n\n'
          'Please restart the Colab notebook and try again.',
        );
      } else {
        String errorDetail = 'Server error: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          if (errorData['detail'] != null) errorDetail = errorData['detail'] as String;
        } catch (_) {
          errorDetail += '\n${response.body}';
        }
        throw Exception(errorDetail);
      }
    } catch (e) {
      print('❌ Report generation error: $e');

      String friendlyMessage;
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        friendlyMessage = 'Network connection error\n\n'
            'Check:\n'
            '• Internet connection is active\n'
            '• Colab server is still running\n'
            '• ngrok URL is correct';
      } else if (e.toString().contains('timeout')) {
        friendlyMessage = e.toString().replaceAll('Exception: ', '');
      } else {
        friendlyMessage = 'Report generation failed:\n\n${e.toString()}';
      }

      setState(() {
        _errorMessage       = friendlyMessage;
        _isGeneratingReport = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Report generation failed. See error above.'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}