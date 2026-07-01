import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxation_card/features/di/widget/dependencies_scope.dart';
import 'package:taxation_card/features/home/bloc/main_tabs_bloc.dart';

final class BrushwoodScreen extends StatefulWidget {
  const BrushwoodScreen({super.key});

  @override
  State<BrushwoodScreen> createState() => _BrushwoodScreenState();
}

final class _BrushwoodScreenState extends State<BrushwoodScreen> with AutomaticKeepAliveClientMixin {
  final _brushwoodPercentController = TextEditingController();
  int? _loadedProbaInfoId;
  double? _lastSavedBrushwoodPercent;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _brushwoodPercentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final selectedProbaInfoId = context.select<MainTabsBloc, int?>((bloc) => bloc.state.selectedProbaInfoId);
    _loadBrushwoodPercentIfNeeded(selectedProbaInfoId);

    return Scaffold(
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: selectedProbaInfoId == null || _isLoading || _isSaving ? null : _onSavePressed,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isSaving
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                  )
                : const Text('Сохранить'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          TextFormField(
            controller: _brushwoodPercentController,
            enabled: selectedProbaInfoId != null && !_isLoading,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _onSavePressed(),
            decoration: InputDecoration(
              labelText: 'Процент хвороста',
              suffixText: '%',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  void _loadBrushwoodPercentIfNeeded(int? selectedProbaInfoId) {
    if (_loadedProbaInfoId == selectedProbaInfoId) {
      return;
    }

    _loadedProbaInfoId = selectedProbaInfoId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _loadedProbaInfoId != selectedProbaInfoId) {
        return;
      }

      if (selectedProbaInfoId == null) {
        setState(() {
          _brushwoodPercentController.clear();
          _lastSavedBrushwoodPercent = null;
          _isLoading = false;
        });
        return;
      }

      unawaited(_loadBrushwoodPercent(selectedProbaInfoId));
    });
  }

  Future<void> _loadBrushwoodPercent(int probaInfoId) async {
    setState(() => _isLoading = true);
    try {
      final repository = DependenciesScope.of(context).probaInfoRepository;
      final probaInfo = await repository.getById(probaInfoId);
      if (!mounted || _loadedProbaInfoId != probaInfoId) {
        return;
      }

      final brushwoodPercent = probaInfo?.brushwoodPercent ?? 0;
      setState(() {
        _lastSavedBrushwoodPercent = brushwoodPercent;
        _brushwoodPercentController.text = _formatNumber(brushwoodPercent);
      });
    } on Object catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Не удалось загрузить процент хвороста.')));
    } finally {
      if (mounted && _loadedProbaInfoId == probaInfoId) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onSavePressed() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await _saveBrushwoodPercent(showSuccess: true);
  }

  Future<void> _saveBrushwoodPercent({bool showSuccess = false}) async {
    if (_isLoading || _isSaving) {
      return;
    }

    final probaInfoId = _loadedProbaInfoId;
    if (probaInfoId == null) {
      return;
    }

    final percent = _parsePercent(_brushwoodPercentController.text);
    if (percent == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введите корректный процент хвороста.')));
      return;
    }

    if (!percent.isFinite || percent < 0 || percent > 100) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Процент должен быть от 0 до 100.')));
      return;
    }

    if (_lastSavedBrushwoodPercent == percent) {
      if (showSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Процент хвороста сохранён.'), duration: Duration(seconds: 1)),
        );
      }
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repository = DependenciesScope.of(context).probaInfoRepository;
      await repository.updateBrushwoodPercent(id: probaInfoId, percent: percent);
      if (!mounted || _loadedProbaInfoId != probaInfoId) {
        return;
      }

      setState(() => _lastSavedBrushwoodPercent = percent);
      if (showSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Процент хвороста сохранён.')));
      }
    } on Object catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Не удалось сохранить процент хвороста.')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  double? _parsePercent(String value) {
    final normalizedValue = value.trim().replaceAll(',', '.');
    if (normalizedValue.isEmpty) {
      return 0;
    }

    return double.tryParse(normalizedValue);
  }

  String _formatNumber(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }

    return value.toString().replaceAll('.', ',');
  }
}
