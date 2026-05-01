import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxation_card/features/deadwood/bloc/deadwood_bloc.dart';

final class DeadwoodScreen extends StatefulWidget {
  const DeadwoodScreen({super.key});

  @override
  State<DeadwoodScreen> createState() => _DeadwoodScreenState();
}

final class _DeadwoodScreenState extends State<DeadwoodScreen>
    with AutomaticKeepAliveClientMixin {
  static const _decayClasses = ['I', 'II', 'III', 'IV', 'V'];

  final _formKey = GlobalKey<FormState>();
  final _volumeController = TextEditingController();
  String? _selectedDecayClass;

  @override
  void initState() {
    super.initState();
    _volumeController.addListener(_onVolumeChanged);
  }

  @override
  void dispose() {
    _volumeController
      ..removeListener(_onVolumeChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocListener<DeadwoodBloc, DeadwoodState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == DeadwoodStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Данные по валёжнику сохранены.')),
          );
        }
      },
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            Text('Валёжник', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Заполните запас валёжника и класс разложения.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _volumeController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration('Запас, м³/га'),
                      validator: _validatePositiveNumber,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedDecayClass,
                      decoration: _inputDecoration('Класс разложения'),
                      items: _decayClasses
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedDecayClass = value);
                        if (value != null) {
                          context.read<DeadwoodBloc>().add(
                            DeadwoodEvent.decayClassChanged(value),
                          );
                        }
                      },
                      validator: (value) =>
                          value == null ? 'Выберите значение' : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            BlocBuilder<DeadwoodBloc, DeadwoodState>(
              builder: (context, state) {
                final isLoading = state.status == DeadwoodStatus.loading;

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

  String? _validatePositiveNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Заполните поле';
    }

    final parsedValue = double.tryParse(value.replaceAll(',', '.').trim());
    if (parsedValue == null || parsedValue <= 0) {
      return 'Введите число больше 0';
    }

    return null;
  }

  void _onVolumeChanged() {
    context.read<DeadwoodBloc>().add(
      DeadwoodEvent.volumeChanged(_volumeController.text),
    );
  }

  void _onSavePressed() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<DeadwoodBloc>().add(const DeadwoodEvent.saved());
    }
  }
}
