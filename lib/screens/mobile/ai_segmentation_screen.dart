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
  
  // CT data
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
          // Header
          _buildHeader(),

          // Content
          Expanded(
            child: _errorMessage != null
                ? _buildErrorView()
                : (_uploadedFile
                    ? _buildCTViewer()
                    : _buildUploadSection()),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 20,
                ),
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
              style: TextStyle(
                fontSize: 14,
                color: Colors.red.shade900,
              ),
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
                  child: const Icon(
                    Icons.upload_file,
                    size: 40,
                    color: Color(0xFF2463EB),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Upload CT Scan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E40AF),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Upload abdomen CT scan in NIFTI format (.nii or .nii.gz)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
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
                    label: Text(_isProcessing ? 'Uploading to Colab...' : 'Select NIFTI File'),
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
          _buildInstructionItem('Upload abdomen CT scan to Colab GPU backend'),
          _buildInstructionItem('View CT slices in axial, coronal, and sagittal planes'),
          _buildInstructionItem('Click "Run AI Segmentation" to process with GPU'),
          _buildInstructionItem('View segmented organs with color overlay'),
          _buildInstructionItem('Generate detailed analysis report'),
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
          const Text(
            '• ',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTViewer() {
    if (_isProcessing) {
      return _buildProcessingIndicator();
    }

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
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xFF2463EB),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isSegmenting ? 'Running AI Segmentation' : 'Processing CT Scan',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E40AF),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _isSegmenting 
                  ? 'GPU processing on Colab...' 
                  : 'Uploading to backend...',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentationStats() {
    if (_segmentationAnalysis == null) return const SizedBox.shrink();

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
              const Text(
                'Segmentation Complete',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF059669),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Found $_organsFound organs',
            style: TextStyle(
              fontSize: 14,
              color: Colors.green.shade900,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _segmentationAnalysis!.keys.map((organ) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Text(
                  organ.toString().replaceAll('_', ' '),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.green.shade900,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFileInfo() {
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
                child: const Icon(
                  Icons.image,
                  size: 20,
                  color: Color(0xFF059669),
                ),
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
                          : 'Processing...',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
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

  Widget _buildViewTabs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'CT Scan Views',
              style: TextStyle(
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
    final isActive = _activeView == value;
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
  List<String> displaySlices;

  if (_segmentationComplete) {
    switch (_activeView) {
      case 'coronal':
        displaySlices = _segmentationCoronalSlices;
        break;
      case 'sagittal':
        displaySlices = _segmentationSagittalSlices;
        break;
      default:
        displaySlices = _segmentationAxialSlices;
    }
  } else {
    displaySlices = _getCurrentSlices();
  }

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

  String base64Image = displaySlices[_currentSliceIndex];

  double aspectRatio = 1.0;

  // Get real slice dimensions if available
  if (_sliceDimensions != null && _sliceDimensions!.containsKey(_activeView)) {
    final dims = _sliceDimensions![_activeView]!;
    int h = dims[0];
    int w = dims[1];

    aspectRatio = w / h;

    // 🔥 KEY FIX: override aspect ratio for tall slices
    if (_activeView == 'sagittal' || _activeView == 'coronal') {
      if (h > w) {
        aspectRatio = 1.2;  // force it wider so content becomes big
      }
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
        // image area
        AspectRatio(
          aspectRatio: aspectRatio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              base64Decode(base64Image),
              fit: BoxFit.fill,   // 🔥 fills the forced aspect ratio box
            ),
          ),
        ),

        const SizedBox(height: 12),

        Text(
          '${_activeView.toUpperCase()} View - '
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
  List<String> displaySlices;
  
  if (_segmentationComplete) {
    switch (_activeView) {
      case 'coronal':
        displaySlices = _segmentationCoronalSlices;
        break;
      case 'sagittal':
        displaySlices = _segmentationSagittalSlices;
        break;
      default:
        displaySlices = _segmentationAxialSlices;
    }
  } else {
    displaySlices = _getCurrentSlices();
  }
  
  if (displaySlices.isEmpty) {
    return const SizedBox.shrink();
  }

  // ... rest of the navigator code


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

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (!_segmentationComplete) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSegmenting ? null : _runSegmentation,
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
              label: Text(_isSegmenting ? 'Running AI...' : 'Run AI Segmentation'),
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
        ] else ...[
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
    label: Text(_isGeneratingReport ? 'Generating...' : 'Generate AI Report'),
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF059669),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
),
        ],
      ],
    );
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

  Future<void> _pickAndUploadFile() async {
    try {
      print('📁 Opening file picker...');
      
      // Pick file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result == null || result.files.single.path == null) {
        print('❌ No file selected');
        return;
      }

      print('📋 Selected file: ${result.files.single.name}');

      setState(() {
        _isProcessing = true;
        _errorMessage = null;
      });

      print('🚀 Uploading to Colab backend: $backendUrl/process-ct');

      // Prepare multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$backendUrl/process-ct'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          result.files.single.path!,
          filename: result.files.single.name,
        ),
      );

      print('⏳ Uploading file to Colab...');

      // Send request with timeout
      var streamedResponse = await request.send().timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          throw Exception('Upload timeout - check your internet connection');
        },
      );
      
      var response = await http.Response.fromStream(streamedResponse);

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Upload successful');
        var data = jsonDecode(response.body);
        
        setState(() {
          _filename = data['filename'];
          _shape = List<int>.from(data['shape']);
          _voxelSizes = List<double>.from(data['voxel_sizes']);
          _sliceDimensions = {
          'axial': List<int>.from(data['slice_dimensions']['axial']),
          'coronal': List<int>.from(data['slice_dimensions']['coronal']),
          'sagittal': List<int>.from(data['slice_dimensions']['sagittal']),
        };
        _axialSlices = List<String>.from(data['axial']);
  _coronalSlices = List<String>.from(data['coronal']);
  _sagittalSlices = List<String>.from(data['sagittal']);
          _uploadedFile = true;
          _isProcessing = false;
          _currentSliceIndex = 0;
        });
        
        print('✅ CT scan uploaded successfully');
      } else {
        throw Exception('Server error: ${response.statusCode}\n${response.body}');
      }
    } catch (e) {
      print('❌ Upload failed: $e');
      setState(() {
        _errorMessage = 'Failed to upload CT scan: $e\n\nCheck:\n- Colab server is running\n- ngrok URL is correct\n- Internet connection is stable';
        _isProcessing = false;
        _uploadedFile = false;
      });
    }
  }

  Future<void> _runSegmentation() async {
  try {
    print('🔬 Starting AI segmentation on Colab GPU...');
    
    setState(() {
      _isSegmenting = true;
      _errorMessage = null;
    });

    print('🚀 Calling segmentation endpoint: $backendUrl/segment');

    final response = await http.post(
      Uri.parse('$backendUrl/segment'),
    ).timeout(
      const Duration(minutes: 10),
      onTimeout: () {
        throw Exception('Segmentation timeout - processing large CT scan');
      },
    );

    print('📥 Segmentation response: ${response.statusCode}');

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      
      print('✅ Segmentation complete!');
      print('   Organs found: ${data['organs_found']}');
      
      setState(() {
        // Store all three segmentation views
        _segmentationAxialSlices = List<String>.from(
          data['segmentation_slices']['axial']
        );
        _segmentationCoronalSlices = List<String>.from(
          data['segmentation_slices']['coronal']
        );
        _segmentationSagittalSlices = List<String>.from(
          data['segmentation_slices']['sagittal']
        );
        
        _segmentationAnalysis = Map<String, dynamic>.from(data['analysis']);
        _organsFound = data['organs_found'];
        _segmentationComplete = true;
        _isSegmenting = false;
        _currentSliceIndex = 0;
        _activeView = 'axial'; // Switch to axial to show segmentation
      });
      
      print('✅ Segmentation results loaded for all views');
    } else {
      throw Exception('Segmentation failed: ${response.statusCode}\n${response.body}');
    }
  } catch (e) {
    print('❌ Segmentation error: $e');
    setState(() {
      _errorMessage = 'AI Segmentation failed: $e\n\nThis may take several minutes for large scans.';
      _isSegmenting = false;
    });
  }
}
Future<void> _generateAIReport() async {
  try {
    print('📊 Generating AI report...');
    
    setState(() {
      _isGeneratingReport = true;
      _errorMessage = null;
    });

    print('🚀 Calling report endpoint: $backendUrl/generate-report');

    final response = await http.post(
      Uri.parse('$backendUrl/generate-report'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ).timeout(
      const Duration(minutes: 3),
      onTimeout: () {
        throw Exception(
          'Report generation is taking longer than expected.\n\n'
          'This can happen with:\n'
          '• Slow Gemini API response\n'
          '• Network connectivity issues\n'
          '• Complex segmentation results\n\n'
          'Try again in a moment.'
        );
      },
    );

    print('📥 Report response: ${response.statusCode}');

    if (response.statusCode == 200) {
      var reportData = jsonDecode(response.body);
      
      // Validate report data
      if (reportData == null || !reportData.containsKey('organs')) {
        throw Exception('Invalid report data received from server');
      }
      
      print('✅ Report generated successfully');
      print('   Organs in report: ${reportData['organs']?.length ?? 0}');
      print('   AI findings length: ${reportData['ai_findings']?.length ?? 0}');
      
      // ✅ DEBUG: Print full data structure
      print('📦 Full report data keys: ${reportData.keys.toList()}');
      print('📦 Scan info: ${reportData['scan_info']}');
      print('📦 Summary: ${reportData['summary']}');
      print('📦 First organ: ${reportData['organs']?[0]}');
      
      setState(() {
        _isGeneratingReport = false;
      });
      
      // ✅ FIX: Pass the report data to parent callback
      // The parent should handle navigation to AIReportScreen
      widget.onGenerateReport(reportData);
      
    } else if (response.statusCode == 400) {
      throw Exception(
        'Segmentation not complete.\n\n'
        'Please run "AI Segmentation" first before generating report.'
      );
    } else if (response.statusCode == 503) {
      throw Exception(
        'Model not loaded on server.\n\n'
        'Please restart the Colab notebook and try again.'
      );
    } else {
      String errorDetail = 'Server error: ${response.statusCode}';
      try {
        var errorData = jsonDecode(response.body);
        if (errorData['detail'] != null) {
          errorDetail = errorData['detail'];
        }
      } catch (e) {
        errorDetail += '\n${response.body}';
      }
      throw Exception(errorDetail);
    }
  } catch (e) {
    print('❌ Report generation error: $e');
    
    String friendlyMessage;
    if (e.toString().contains('SocketException') || 
        e.toString().contains('Failed host lookup')) {
      friendlyMessage = 
        'Network connection error\n\n'
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
      _errorMessage = friendlyMessage;
      _isGeneratingReport = false;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report generation failed. See error above.'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }}}