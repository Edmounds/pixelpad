import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:pixelpad/core/theme/app_theme.dart';
import 'package:pixelpad/features/make/data/bean_preset_storage.dart';
import 'package:pixelpad/features/make/data/make_pipeline_result.dart';
import 'package:pixelpad/features/make/data/make_pipeline_service.dart';
import 'package:pixelpad/features/make/data/pixel_renderer.dart';
import 'package:pixelpad/features/make/presentation/screens/make_result_screen.dart';
import 'package:pixelpad/features/make/presentation/widgets/value_picker_bottom_sheet.dart';

class MakeParameterScreen extends StatefulWidget {
  static const Key maxColorsCardKey = ValueKey<String>(
    'make-parameter-max-colors-card',
  );
  static const Key processButtonKey = ValueKey<String>(
    'make-parameter-process-button',
  );
  static const Key confirmButtonKey = ValueKey<String>(
    'make-parameter-confirm-button',
  );

  final Uint8List imageBytes;
  final MakePipelineService? pipelineService;

  const MakeParameterScreen({
    super.key,
    required this.imageBytes,
    this.pipelineService,
  });

  @override
  State<MakeParameterScreen> createState() => _MakeParameterScreenState();
}

class _MakeParameterScreenState extends State<MakeParameterScreen> {
  static const int _defaultMaxColors = 24;
  static const int _defaultTolerance = 5;

  late final MakePipelineService _pipelineService;
  MakePipelineSession? _session;
  MakePipelineResult? _latestResult;
  Uint8List? _previewBytes;
  bool _initializing = true;
  bool _processing = false;
  String? _error;
  int _draftMaxColors = _defaultMaxColors;
  int _appliedMaxColors = _defaultMaxColors;
  int _draftTolerance = _defaultTolerance;
  int _appliedTolerance = _defaultTolerance;

  bool get _hasProcessedResult => _latestResult != null;
  bool get _isDirty =>
      _draftMaxColors != _appliedMaxColors ||
      _draftTolerance != _appliedTolerance;
  bool get _canConfirm => _hasProcessedResult && !_processing && !_isDirty;

  @override
  void initState() {
    super.initState();
    _pipelineService = widget.pipelineService ?? MakePipelineService();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _initializing = true;
      _error = null;
    });
    try {
      final BeanPreset preset = await BeanPresetStorage.load();
      final MakePipelineSession session = await _pipelineService.initializeSession(
        imageBytes: widget.imageBytes,
        settingsFile: preset.settingsFile,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _session = session;
      });
      await _runProcessing();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = (error is MakePipelineException)
            ? error.message
            : '处理失败，请稍后重试';
      });
    } finally {
      if (mounted) {
        setState(() {
          _initializing = false;
        });
      }
    }
  }

  Future<void> _runProcessing() async {
    final MakePipelineSession? session = _session;
    if (session == null || _processing) {
      return;
    }
    setState(() {
      _processing = true;
      _error = null;
    });
    try {
      final MakePipelineResult result = await _pipelineService.processWithParameters(
        sessionId: session.sessionId,
        sessionWidth: session.width,
        sessionHeight: session.height,
        perfectWidth: session.perfectWidth,
        perfectHeight: session.perfectHeight,
        maxColors: _draftMaxColors,
        tolerance: _draftTolerance,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _latestResult = result;
        _appliedMaxColors = _draftMaxColors;
        _appliedTolerance = _draftTolerance;
        _processing = false;
      });
      _renderPreview(result);
    } catch (error) {
      if (!mounted) {
        return;
      }
      final String message = (error is MakePipelineException)
          ? error.message
          : '处理失败，请稍后重试';
      setState(() {
        _error = message;
        _processing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _renderPreview(MakePipelineResult result) async {
    try {
      final Uint8List? previewBytes = await renderPixelPng(
        width: result.width,
        height: result.height,
        mapping: result.mapping,
        palette: result.palette,
        bgMask: result.bgMask,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _previewBytes = previewBytes;
      });
    } catch (_) {
      // Keep the processed result available even if preview rendering fails.
    }
  }

  Future<void> _openMaxColorsPicker() async {
    final int? value = await ValuePickerBottomSheet.show(
      context,
      title: '选择最大颜色数',
      initialValue: _draftMaxColors,
      minValue: 1,
      maxValue: 295,
    );
    if (value == null || value == _draftMaxColors || !mounted) {
      return;
    }
    setState(() {
      _draftMaxColors = value;
    });
  }

  Future<void> _handleConfirm() async {
    final MakePipelineResult? result = _latestResult;
    if (!_canConfirm || result == null) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => MakeResultScreen(
          mapping: result.mapping,
          palette: result.palette,
          bgMask: result.bgMask,
          width: result.width,
          height: result.height,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.header,
        title: const Text('参数调节'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PreviewCard(
                      child: _buildPreviewContent(),
                    ),
                    const SizedBox(height: 18),
                    _ParameterCard(
                      key: MakeParameterScreen.maxColorsCardKey,
                      title: '最大颜色数',
                      value: '$_draftMaxColors',
                      subtitle: '点击选择颜色数量',
                      onTap: _openMaxColorsPicker,
                    ),
                    const SizedBox(height: 12),
                    _ToleranceCard(
                      value: _draftTolerance,
                      onChanged: (double value) {
                        setState(() {
                          _draftTolerance = value.round();
                        });
                      },
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFF9F871),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              color: AppColors.header,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      key: MakeParameterScreen.processButtonKey,
                      onPressed:
                          (_processing || _session == null) ? null : _runProcessing,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF9F871),
                        foregroundColor: const Color(0xFF232323),
                      ),
                      child: Text(_processing ? '处理中...' : '处理图像'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      key: MakeParameterScreen.confirmButtonKey,
                      onPressed: _canConfirm ? _handleConfirm : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E2E2E),
                        foregroundColor: AppColors.white,
                      ),
                      child: const Text('确认参数'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewContent() {
    if (_initializing && !_hasProcessedResult) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_processing && !_hasProcessedResult) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_previewBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox.expand(
          child: Image.memory(
            _previewBytes!,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none,
            isAntiAlias: false,
          ),
        ),
      );
    }
    return Center(
      child: Text(
        _error ?? '请先处理图像',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF9A9A9A),
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final Widget child;

  const _PreviewCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.all(12),
      child: child,
    );
  }
}

class _ParameterCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final VoidCallback onTap;

  const _ParameterCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF2A2A2A),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB5B5B5),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF9F871),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: AppColors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToleranceCard extends StatelessWidget {
  final int value;
  final ValueChanged<double> onChanged;

  const _ToleranceCard({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '去除背景力度',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF9F871),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Slider(
            value: value.toDouble(),
            min: 1,
            max: 50,
            divisions: 49,
            activeColor: const Color(0xFFF9F871),
            inactiveColor: AppColors.white.withValues(alpha: 0.2),
            label: '$value',
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
