// lib/screens/mobile/segmentation_quiz_screen.dart
//
// Replaces the old standalone quiz_screen.dart.
// Now talks to Node.js (which proxies to FastAPI) instead of FastAPI directly.
// The test config (niftiFileUrl, labelFileUrl, sliceNum, axis) all come from
// MongoDB via Node.js – Flutter never needs to know where files live.

import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/api_service.dart';
import 'segmentation_result_screen.dart';
import 'dart:async';
import 'dart:typed_data';

// ─── Data model ───────────────────────────────────────────────────────────────

/// One CT case inside the segmentation test.
class SegmentationCase {
  final String id;
  final String description;
  final String organLabel;
  final int    sliceNum;
  final int    axis;

  const SegmentationCase({
    required this.id,
    required this.description,
    required this.organLabel,
    required this.sliceNum,
    required this.axis,
  });

  factory SegmentationCase.fromJson(Map<String, dynamic> j) =>
      SegmentationCase(
        id:          j['_id'] as String? ?? '',
        description: j['description'] as String? ?? '',
        organLabel:  j['organLabel'] as String? ?? '',
        sliceNum:    (j['sliceNum'] as num?)?.toInt() ?? 0,
        axis:        (j['axis'] as num?)?.toInt() ?? 2,
      );
}

/// Per-organ breakdown result.
class OrganResult {
  final String organ;
  final double dice;
  final int    gtPixels;
  final String status;   // 'hit' | 'partial' | 'missed'

  const OrganResult({
    required this.organ,
    required this.dice,
    required this.gtPixels,
    required this.status,
  });

  factory OrganResult.fromJson(Map<String, dynamic> j) => OrganResult(
    organ:    j['organ']    as String,
    dice:     (j['dice']    as num).toDouble(),
    gtPixels: (j['gtPixels'] as num).toInt(),
    status:   j['status']  as String,
  );

  Map<String, dynamic> toJson() => {
    'organ': organ, 'dice': dice,
    'gtPixels': gtPixels, 'status': status,
  };
}

/// Scored result for one case – mirrors caseResultSchema in MongoDB.
class CaseResult {
  final String       caseId;
  final double?      diceScore;
  final double?      iouScore;
  final double?      precision;
  final double?      recall;
  final int?         truePositives;
  final int?         falsePositives;
  final int?         falseNegatives;
  final int?         groundTruthPixels;
  final int?         annotatedPixels;
  final String?      grade;
  final List<String> feedback;
  final List<OrganResult> organBreakdown;
  final bool         attempted;

  const CaseResult({
    required this.caseId,
    this.diceScore,
    this.iouScore,
    this.precision,
    this.recall,
    this.truePositives,
    this.falsePositives,
    this.falseNegatives,
    this.groundTruthPixels,
    this.annotatedPixels,
    this.grade,
    this.feedback = const [],
    this.organBreakdown = const [],
    this.attempted = false,
  });

  factory CaseResult.fromJson(Map<String, dynamic> j) => CaseResult(
        caseId:            j['caseId'] as String? ?? '',
        diceScore:         (j['diceScore'] as num?)?.toDouble(),
        iouScore:          (j['iouScore'] as num?)?.toDouble(),
        precision:         (j['precision'] as num?)?.toDouble(),
        recall:            (j['recall'] as num?)?.toDouble(),
        truePositives:     (j['truePositives'] as num?)?.toInt(),
        falsePositives:    (j['falsePositives'] as num?)?.toInt(),
        falseNegatives:    (j['falseNegatives'] as num?)?.toInt(),
        groundTruthPixels: (j['groundTruthPixels'] as num?)?.toInt(),
        annotatedPixels:   (j['annotatedPixels'] as num?)?.toInt(),
        grade:             j['grade'] as String?,
        feedback:          List<String>.from(j['feedback'] as List? ?? []),
        organBreakdown: (j['organBreakdown'] as List? ?? [])
            .map((o) => OrganResult.fromJson(o as Map<String, dynamic>))
            .toList(),
        attempted:         j['attempted'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'caseId':            caseId,
        'diceScore':         diceScore,
        'iouScore':          iouScore,
        'precision':         precision,
        'recall':            recall,
        'truePositives':     truePositives,
        'falsePositives':    falsePositives,
        'falseNegatives':    falseNegatives,
        'groundTruthPixels': groundTruthPixels,
        'annotatedPixels':   annotatedPixels,
        'grade':             grade,
        'feedback':          feedback,
        'organBreakdown':    organBreakdown.map((o) => o.toJson()).toList(),
        'attempted':         attempted,
      };
}

// ─── Drawing model ────────────────────────────────────────────────────────────

class DrawingPoint {
  final Offset? offset;
  final Paint   paint;
  DrawingPoint({required this.offset, required this.paint});
}

// ─── Widget ───────────────────────────────────────────────────────────────────

class SegmentationQuizScreen extends StatefulWidget {
  /// The MongoDB _id of the SegmentationTest document.
  final String testId;
  final VoidCallback onBack;
  final void Function(
    String testId,
    String testTitle,
    List<CaseResult> caseResults,
    Map<String, dynamic> overallData,
  ) onComplete; 

  const SegmentationQuizScreen({
    Key? key,
    required this.testId,
    required this.onBack,
    required this.onComplete, 
  }) : super(key: key);

  @override
  State<SegmentationQuizScreen> createState() => _SegmentationQuizScreenState();
}

class _SegmentationQuizScreenState extends State<SegmentationQuizScreen> {
  // ── Test meta ─────────────────────────────────────────────────────────────
  Map<String, dynamic>? _testData;
  List<SegmentationCase> _cases = [];
  int _currentCaseIndex = 0;

  // ── Per-case scoring results accumulated locally ──────────────────────────
  final List<CaseResult?> _caseResults = [];

  // ── CT image state ────────────────────────────────────────────────────────
  ui.Image? _ctImage;
  bool _imageLoading = true;
  String? _imageError;

  // ── Canvas size for coordinate scaling ────────────────────────────────────
  Size _canvasSize = Size.zero;

  // ── Drawing state ─────────────────────────────────────────────────────────
  final List<DrawingPoint> _points = [];
  double _brushSize = 10.0;
  bool   _isEraser  = false;

  // ── Submission state ──────────────────────────────────────────────────────
  bool _submittingCase = false;
  bool _finalisingTest = false;

  // ── Loading state ─────────────────────────────────────────────────────────
  bool   _loadingTest = true;
  String? _testError;

  @override
  void initState() {
    super.initState();
    _loadTest();
  }

  // ─── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadTest() async {
    setState(() { _loadingTest = true; _testError = null; });
    try {
      final result = await ApiService.getSegmentationTest(widget.testId);
      if (!mounted) return;

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'] as Map<String, dynamic>;
        final rawCases = (data['segmentationCases'] as List?) ?? [];
        final cases = rawCases.map((c) => SegmentationCase.fromJson(c as Map<String, dynamic>)).toList();

        setState(() {
          _testData = data;
          _cases    = cases;
          _caseResults.addAll(List<CaseResult?>.filled(cases.length, null));
          _loadingTest = false;
        });

        // Restore any persisted progress (if app was killed mid-quiz)
        await _restoreCaseResults();

        if (cases.isNotEmpty) await _loadCTImage(0);
      } else {
        setState(() { _testError = result['message'] ?? 'Failed to load test'; _loadingTest = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _testError = e.toString(); _loadingTest = false; });
    }
  }

  Future<void> _loadCTImage(int caseIndex) async {
    setState(() { _imageLoading = true; _imageError = null; _ctImage = null; });
    try {
      // Node.js proxies to FastAPI: GET /api/segmentation-tests/:id/slice/:caseIndex
      final bytes = await ApiService.getSegmentationSlice(
        testId:     widget.testId,
        caseIndex:  caseIndex,
      );
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (!mounted) return;
      setState(() { _ctImage = frame.image; _imageLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _imageError = e.toString(); _imageLoading = false; });
    }
  }

  // ─── Drawing ───────────────────────────────────────────────────────────────

  void _onPanStart(DragStartDetails d) => _addPoint(d.localPosition);
  void _onPanUpdate(DragUpdateDetails d) => _addPoint(d.localPosition);
  void _onPanEnd(DragEndDetails _) {
    setState(() {
      _points.add(DrawingPoint(offset: null, paint: Paint()));
    });
  }

  void _addPoint(Offset offset) {
    setState(() {
      _points.add(DrawingPoint(
        offset: offset,
        paint: Paint()
          ..color       = _isEraser ? Colors.black : Colors.white
          ..strokeWidth = _brushSize
          ..strokeCap   = StrokeCap.round
          ..blendMode   = _isEraser ? BlendMode.clear : BlendMode.srcOver,
      ));
    });
  }
  void _clearDrawing() => setState(() => _points.clear());

  // ─── Mask creation ─────────────────────────────────────────────────────────

  Future<File> _createMaskImage() async {
  final ctW = _ctImage!.width.toDouble();
  final ctH = _ctImage!.height.toDouble();
  final scaleX = ctW / _canvasSize.width;
  final scaleY = ctH / _canvasSize.height;

  // Step 1 — draw strokes onto a native-resolution canvas
  final recorder = ui.PictureRecorder();
  final canvas   = Canvas(recorder);

  canvas.drawRect(
    Rect.fromLTWH(0, 0, ctW, ctH),
    Paint()..color = Colors.black,
  );

  for (int i = 0; i < _points.length - 1; i++) {
    final p1 = _points[i];
    final p2 = _points[i + 1];
    if (p1.offset == null || p2.offset == null) continue;

    final isEraser = p1.paint.blendMode == BlendMode.clear;
    canvas.drawLine(
      Offset(p1.offset!.dx * scaleX, p1.offset!.dy * scaleY),
      Offset(p2.offset!.dx * scaleX, p2.offset!.dy * scaleY),
      Paint()
        ..color       = isEraser ? Colors.black : Colors.white
        ..strokeWidth = p1.paint.strokeWidth * ((scaleX + scaleY) / 2)
        ..strokeCap   = StrokeCap.round
        ..style       = PaintingStyle.stroke,
    );
  }

  // Step 2 — rasterize to pixel array
  final picture  = recorder.endRecording();
  final img      = await picture.toImage(ctW.toInt(), ctH.toInt());
  final byteData = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
  final pixels   = byteData!.buffer.asUint8List();

  final w = ctW.toInt();
  final h = ctH.toInt();

  // Step 3 — build binary grid (1 = white stroke, 0 = black background)
  final grid = List.generate(h, (y) =>
    List.generate(w, (x) {
      final idx = (y * w + x) * 4;
      return pixels[idx] > 50 ? 1 : 0;   // red channel threshold
    })
  );

  // Step 4 — flood fill from all 4 edges to find outside pixels
  // Any pixel reachable from the border WITHOUT crossing a stroke = outside
  final outside = List.generate(h, (_) => List.filled(w, false));
  final queue   = <List<int>>[];

  // Seed from all border pixels that are background
  for (int x = 0; x < w; x++) {
    if (grid[0][x]     == 0) { outside[0][x]     = true; queue.add([0, x]); }
    if (grid[h-1][x]   == 0) { outside[h-1][x]   = true; queue.add([h-1, x]); }
  }
  for (int y = 0; y < h; y++) {
    if (grid[y][0]     == 0) { outside[y][0]     = true; queue.add([y, 0]); }
    if (grid[y][w-1]   == 0) { outside[y][w-1]   = true; queue.add([y, w-1]); }
  }

  // BFS flood fill outward
  const dy = [-1, 1, 0, 0];
  const dx = [0, 0, -1, 1];
  int head = 0;
  while (head < queue.length) {
    final cell = queue[head++];
    final cy = cell[0];
    final cx = cell[1];
    for (int d = 0; d < 4; d++) {
      final ny = cy + dy[d];
      final nx = cx + dx[d];
      if (ny < 0 || ny >= h || nx < 0 || nx >= w) continue;
      if (outside[ny][nx] || grid[ny][nx] == 1) continue;  // skip strokes and already visited
      outside[ny][nx] = true;
      queue.add([ny, nx]);
    }
  }

  // Step 5 — build final mask:
  //   white = stroke pixel OR enclosed interior pixel
  //   black = outside background
  final maskPixels = Uint8List(w * h * 4);
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final i   = (y * w + x) * 4;
      final val = (grid[y][x] == 1 || !outside[y][x]) ? 255 : 0;
      maskPixels[i]     = val;   // R
      maskPixels[i + 1] = val;   // G
      maskPixels[i + 2] = val;   // B
      maskPixels[i + 3] = 255;   // A
    }
  }

  // Step 6 — encode to PNG
  final completer    = Completer<ui.Image>();
  ui.decodeImageFromPixels(maskPixels, w, h, ui.PixelFormat.rgba8888,
      (result) => completer.complete(result));
  final filledImg  = await completer.future;
  final filledData = await filledImg.toByteData(format: ui.ImageByteFormat.png);

  final tmp  = await getTemporaryDirectory();
  final file = File('${tmp.path}/mask_${DateTime.now().millisecondsSinceEpoch}.png');
  await file.writeAsBytes(filledData!.buffer.asUint8List());
  return file;
}

  // ─── Submit one case ──────────────────────────────────────────────────────

  Future<void> _submitCurrentCase() async {
    if (_points.isEmpty || _submittingCase || _ctImage == null) return;

    setState(() => _submittingCase = true);
    try {
      final maskFile = await _createMaskImage();

      // Node.js POST /api/segmentation-tests/:id/submit-case/:caseIndex
      final result = await ApiService.submitSegmentationCase(
        testId: widget.testId,
        caseIndex: _currentCaseIndex,
        maskFile: maskFile,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final scored = CaseResult.fromJson(
          result['data']['caseResult'] as Map<String, dynamic>
        );
        setState(() { _caseResults[_currentCaseIndex] = scored; });

        // Persist progress after each scored case
        await _persistCaseResults();

        _showCaseResult(scored);
      } else {
        _showError(result['message'] ?? 'Scoring failed');
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _submittingCase = false);
    }
  }

  // ─── Navigate between cases ────────────────────────────────────────────────

  Future<void> _goToCase(int index) async {
    setState(() {
      _currentCaseIndex = index;
      _points.clear();
      _isEraser = false;
    });
    await _loadCTImage(index);
  }

  // ─── Finalise test ─────────────────────────────────────────────────────────

  Future<void> _finaliseTest() async {
    // Any unscored cases are marked as not attempted
    final results = List<CaseResult>.generate(_cases.length, (i) {
      return _caseResults[i] ?? 
          CaseResult(
            caseId:    _cases[i].id,
            attempted: false,
            feedback:  ['Case was not attempted'],
          );
    });

    // If any remain unattempted, ask the user to confirm
    final unattemptedIndices = _caseResults
        .asMap()
        .entries
        .where((e) => e.value == null)
        .map((e) => e.key)
        .toList();    if (unattemptedIndices.isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Unscored cases'),
          content: Text('${unattemptedIndices.map((i) => 'Case ${i + 1}').join(', ')} will be marked as not attempted. Continue?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Go back')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Submit anyway')),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _finalisingTest = true);
    try {
      // Node.js POST /api/segmentation-tests/:id/finalise
      final result = await ApiService.finaliseSegmentationTest(
        testId:      widget.testId,
        caseResults: results.map((r) => r.toJson()).toList(),
      );

      if (!mounted) return;

      if (result['success'] == true) {
        // Clear persisted progress now that test is finalised successfully
        await _clearPersistedResults();

        // Call onComplete callback with results
        if (mounted) {
          widget.onComplete(
            widget.testId,
            _testData?['title'] ?? 'Segmentation Test',
            results,
            result['data'] as Map<String, dynamic>,
          );
        }
      } else {
        _showError(result['message'] ?? 'Failed to submit test');
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _finalisingTest = false);
    }
  }

  // ─── Persistence helpers ───────────────────────────────────────────────────

  Future<void> _persistCaseResults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_caseResults.map((r) => r?.toJson()).toList());
      await prefs.setString('quiz_results_${widget.testId}', encoded);
    } catch (e) {
      debugPrint('Failed to persist case results: $e');
    }
  }

  Future<void> _restoreCaseResults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('quiz_results_${widget.testId}');
      if (raw == null) return;
      final list = jsonDecode(raw) as List<dynamic>;
      for (int i = 0; i < list.length && i < _caseResults.length; i++) {
        if (list[i] != null) {
          _caseResults[i] = CaseResult.fromJson(list[i] as Map<String, dynamic>);
        }
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Failed to restore case results: $e');
    }
  }

  Future<void> _clearPersistedResults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('quiz_results_${widget.testId}');
    } catch (e) {
      debugPrint('Failed to clear persisted results: $e');
    }
  }

  // ─── UI helpers ────────────────────────────────────────────────────────────

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
    );
  }
  void _showCaseResult(CaseResult result) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(children: [
          Icon(Icons.check_circle, color: Colors.green.shade600),
          const SizedBox(width: 8),
          const Text('Case Scored'),
        ]),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // ── Overall scores ──────────────────────────────────────
              _scoreRow('Dice',      result.diceScore),
              _scoreRow('IoU',       result.iouScore),
              _scoreRow('Precision', result.precision),
              _scoreRow('Recall',    result.recall),
              const SizedBox(height: 8),
              Text(
                'Grade: ${result.grade ?? "N/A"}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              // ── General feedback ────────────────────────────────────
              if (result.feedback.isNotEmpty) ...[
                const Divider(height: 20),
                ...result.feedback.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('• ', style: TextStyle(fontSize: 13)),
                    Expanded(child: Text(f, style: const TextStyle(fontSize: 13))),
                  ]),
                )),
              ],

              // ── Per-organ breakdown ─────────────────────────────────
              if (result.organBreakdown.isNotEmpty) ...[
                const Divider(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Organ breakdown',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B)),
                  ),
                ),
                const SizedBox(height: 8),
                ...result.organBreakdown.map((o) => _organRow(o)),
              ],
            ]),
          ),
        ),
        actions: [
          if (_currentCaseIndex < _cases.length - 1)
            TextButton(
              onPressed: () { Navigator.pop(context); _goToCase(_currentCaseIndex + 1); },
              child: const Text('Next case →'),
            ),
          if (_currentCaseIndex == _cases.length - 1)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
              onPressed: () { Navigator.pop(context); _finaliseTest(); },
              child: const Text('Submit test', style: TextStyle(color: Colors.white)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Review drawing'),
          ),
        ],
      ),
    );
  }

  Widget _scoreRow(String label, double? value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Color(0xFF64748B))),
      Text(
        value != null ? '${value.toStringAsFixed(1)}%' : '—',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ]),
  );

  Widget _organRow(OrganResult o) {
    final Color bgColor;
    final Color textColor;
    final String label;

    switch (o.status) {
      case 'hit':
        bgColor   = Colors.green.shade50;
        textColor = Colors.green.shade800;
        label     = 'Hit';
        break;
      case 'partial':
        bgColor   = Colors.orange.shade50;
        textColor = Colors.orange.shade800;
        label     = 'Partial';
        break;
      default:
        bgColor   = Colors.red.shade50;
        textColor = Colors.red.shade800;
        label     = 'Missed';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Expanded(
          child: Text(
            o.organ,
            style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
          ),
        ),
        // Dice bar
        SizedBox(
          width: 80,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: o.dice / 100,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                o.status == 'hit'     ? Colors.green.shade400
                : o.status == 'partial' ? Colors.orange.shade400
                : Colors.red.shade300,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${o.dice.toStringAsFixed(0)}%',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label, style: TextStyle(fontSize: 11, color: textColor,
              fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loadingTest) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))));
    }
    if (_testError != null) {
      return Scaffold(
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(_testError!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadTest, child: const Text('Retry')),
        ])),
      );
    }

    final currentCase = _cases.isNotEmpty ? _cases[_currentCaseIndex] : null;
    final alreadyScored = _caseResults[_currentCaseIndex] != null;

    // Wrap with WillPopScope to guard against accidental back navigation
    return WillPopScope(
      onWillPop: () async {
        final hasProgress = _caseResults.any((r) => r != null);
        if (!hasProgress) {
          widget.onBack();
          return false; // we handled navigation
        }

        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Leave quiz?'),
            content: const Text('Your scored cases are saved locally and will resume next time.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Stay')),
              TextButton(onPressed: () => Navigator.pop(context, true),  child: const Text('Leave')),
            ],
          ),
        );

        if (confirmed == true) {
          widget.onBack();
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Column(children: [
          // ── Header ──────────────────────────────────────────────────────────
          Container(
            color: Colors.white,
            child: SafeArea(bottom: false, child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF1E40AF)),
                    padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(
                    _testData?['title'] ?? 'Segmentation Test',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                    overflow: TextOverflow.ellipsis,
                  )),
                  if (_finalisingTest)
                    const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB))),
                ]),

                // Case tabs
                if (_cases.length > 1) ...[
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: List.generate(_cases.length, (i) {
                      final scored = _caseResults[i] != null;
                      final active = i == _currentCaseIndex;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => _goToCase(i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: active ? const Color(0xFF2563EB) : (scored ? Colors.green.shade100 : Colors.grey.shade100),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: active ? const Color(0xFF2563EB) : Colors.transparent),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              if (scored) const Icon(Icons.check, size: 14, color: Colors.green),
                              if (scored) const SizedBox(width: 4),
                              Text('Case ${i + 1}',
                                style: TextStyle(
                                  color: active ? Colors.white : (scored ? Colors.green.shade700 : const Color(0xFF64748B)),
                                  fontSize: 12, fontWeight: FontWeight.w600,
                                )),
                            ]),
                          ),
                        ),
                      );
                    })),
                  ),
                ],                // Case description
                if (currentCase != null) ...[
                  const SizedBox(height: 6),
                  const Text(
                    'Segment all visible organs on this slice',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ]),
            )),
          ),

          // ── Canvas ──────────────────────────────────────────────────────────
          Expanded(child: _imageLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _imageError != null
                  ? Center(child: Text(_imageError!, style: const TextStyle(color: Colors.red)))
                  : _ctImage == null
                      ? const Center(child: Text('No image', style: TextStyle(color: Colors.white)))                      : LayoutBuilder(
                          builder: (context, constraints) {
                            _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
                            return GestureDetector(
                              onPanStart:  alreadyScored ? null : _onPanStart,
                              onPanUpdate: alreadyScored ? null : _onPanUpdate,
                              onPanEnd:    alreadyScored ? null : _onPanEnd,
                              child: CustomPaint(
                                size: Size(constraints.maxWidth, constraints.maxHeight),
                                painter: _QuizPainter(
                                  ctImage:    _ctImage!,
                                  points:     _points,
                                  pointCount: _points.length,
                                ),
                              ),
                            );
                          },
                        ),
          ),

          // ── Tools bar ───────────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Brush slider
              Row(children: [
                Icon(_isEraser ? Icons.cleaning_services : Icons.brush,
                    color: _isEraser ? Colors.red : const Color(0xFF2563EB)),
                const SizedBox(width: 8),
                Expanded(child: Slider(
                  value: _brushSize, min: 5, max: 50, divisions: 9,
                  label: '${_brushSize.toInt()}px',
                  activeColor: const Color(0xFF2563EB),
                  onChanged: alreadyScored ? null : (v) => setState(() => _brushSize = v),
                )),
                Text('${_brushSize.toInt()}px', style: const TextStyle(fontSize: 12)),
              ]),

              const SizedBox(height: 8),

              Row(children: [
                // Eraser toggle
                Expanded(child: OutlinedButton.icon(
                  onPressed: alreadyScored ? null : () => setState(() => _isEraser = !_isEraser),
                  icon: Icon(_isEraser ? Icons.brush : Icons.cleaning_services, size: 18),
                  label: Text(_isEraser ? 'Brush' : 'Eraser'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _isEraser ? Colors.red : const Color(0xFF2563EB),
                    side: BorderSide(color: _isEraser ? Colors.red : const Color(0xFF2563EB)),
                  ),
                )),
                const SizedBox(width: 8),

                // Clear
                Expanded(child: OutlinedButton.icon(
                  onPressed: (alreadyScored || _points.isEmpty) ? null : _clearDrawing,
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('Clear'),
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
                )),
                const SizedBox(width: 8),

                // Submit / Next
                Expanded(child: alreadyScored
                    ? ElevatedButton.icon(
                        onPressed: _currentCaseIndex < _cases.length - 1
                            ? () => _goToCase(_currentCaseIndex + 1)
                            : _finalisingTest ? null : _finaliseTest,
                        icon: _finalisingTest
                            ? const SizedBox(width: 16, height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Icon(_currentCaseIndex < _cases.length - 1 ? Icons.arrow_forward : Icons.check),
                        label: Text(_currentCaseIndex < _cases.length - 1 ? 'Next' : 'Finish'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      )
                    : ElevatedButton.icon(
                        onPressed: (_points.isEmpty || _submittingCase) ? null : _submitCurrentCase,
                        icon: _submittingCase
                            ? const SizedBox(width: 16, height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send, size: 18),
                        label: const Text('Score'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                      ),
                ),
              ]),
            ])),
          ),
        ]),
      ),
    );
  }
}

// ─── Painter ─────────────────────────────────────────────────────────────────

class _QuizPainter extends CustomPainter {
  final ui.Image ctImage;
  final List<DrawingPoint> points;
  final int pointCount;

  const _QuizPainter({required this.ctImage, required this.points, required this.pointCount});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw CT image scaled to canvas size
    final src = Rect.fromLTWH(0, 0, ctImage.width.toDouble(), ctImage.height.toDouble());
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(ctImage, src, dst, Paint());

    // Points are in widget local coordinates (matching dst size). If points were
    // recorded in the same coordinate space (d.localPosition) they map directly.
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i].offset != null && points[i + 1].offset != null) {
        final p1 = points[i].offset!;
        final p2 = points[i + 1].offset!;

        // Use stored paint to decide overlay color (eraser vs brush).
        final useEraser = points[i].paint.blendMode == BlendMode.clear;
        final overlayPaint = Paint()
          ..color = useEraser ? Colors.black.withOpacity(0.6) : Colors.red.withOpacity(0.55)
          ..strokeWidth = points[i].paint.strokeWidth
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

        canvas.drawLine(p1, p2, overlayPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QuizPainter old) => old.pointCount != pointCount || old.ctImage != ctImage;
}