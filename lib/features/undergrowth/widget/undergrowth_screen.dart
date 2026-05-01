import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxation_card/features/undergrowth/bloc/undergrowth_bloc.dart';

final class UndergrowthScreen extends StatefulWidget {
  const UndergrowthScreen({super.key});

  @override
  State<UndergrowthScreen> createState() => _UndergrowthScreenState();
}

final class _UndergrowthScreenState extends State<UndergrowthScreen>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _speciesController = TextEditingController();
  final _quantityController = TextEditingController();
  final _heightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _speciesController.addListener(_onSpeciesChanged);
    _quantityController.addListener(_onQuantityChanged);
    _heightController.addListener(_onHeightChanged);
  }

  @override
  void dispose() {
    _speciesController.removeListener(_onSpeciesChanged);
    _quantityController.removeListener(_onQuantityChanged);
    _heightController.removeListener(_onHeightChanged);
    _speciesController.dispose();
    _quantityController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocListener<UndergrowthBloc, UndergrowthState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == UndergrowthStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Данные подроста/подлеска сохранены.'),
            ),
          );
        }
      },
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            Text(
              'Подрост/подлесок',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Укажите породу, количество и среднюю высоту подроста или подлеска.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _speciesController,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration('Порода/вид'),
                      validator: _validateRequired,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration('Количество, шт/га'),
                      validator: _validatePositiveNumber,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _heightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _inputDecoration('Средняя высота, м'),
                      validator: (value) =>
                          _validatePositiveNumber(value, allowDecimal: true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            BlocBuilder<UndergrowthBloc, UndergrowthState>(
              builder: (context, state) {
                final isLoading = state.status == UndergrowthStatus.loading;

                return FilledButton(
                  onPressed: isLoading ? null : _onSavePressed,
                  child: isLoading
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : const Text('Сохранить'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  InputDecoration _inputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    );
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Заполните поле';
    }

    return null;
  }

  String? _validatePositiveNumber(String? value, {bool allowDecimal = false}) {
    if (value == null || value.trim().isEmpty) {
      return 'Заполните поле';
    }

    final normalized = value.replaceAll(',', '.').trim();
    final parsedValue = allowDecimal
        ? double.tryParse(normalized)
        : int.tryParse(normalized);

    if (parsedValue == null || parsedValue <= 0) {
      return 'Введите число больше 0';
    }

    return null;
  }

  void _onSpeciesChanged() {
    context.read<UndergrowthBloc>().add(
      UndergrowthEvent.speciesChanged(_speciesController.text),
    );
  }

  void _onQuantityChanged() {
    context.read<UndergrowthBloc>().add(
      UndergrowthEvent.quantityChanged(_quantityController.text),
    );
  }

  void _onHeightChanged() {
    context.read<UndergrowthBloc>().add(
      UndergrowthEvent.heightChanged(_heightController.text),
    );
  }

  void _onSavePressed() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<UndergrowthBloc>().add(const UndergrowthEvent.saved());
    }
  }
}
