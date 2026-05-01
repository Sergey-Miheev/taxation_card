import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxation_card/features/soils/bloc/soils_bloc.dart';

final class SoilsScreen extends StatefulWidget {
  const SoilsScreen({super.key});

  @override
  State<SoilsScreen> createState() => _SoilsScreenState();
}

final class _SoilsScreenState extends State<SoilsScreen>
    with AutomaticKeepAliveClientMixin {
  static const _soilTypes = [
    'Подзолистая',
    'Дерново-подзолистая',
    'Болотная',
    'Серая лесная',
    'Чернозёмная',
  ];
  static const _moistureOptions = [
    'Сухая',
    'Свежая',
    'Влажная',
    'Сырая',
    'Мокрая',
  ];

  final _formKey = GlobalKey<FormState>();
  String? _selectedSoilType;
  String? _selectedMoisture;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocListener<SoilsBloc, SoilsState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == SoilsStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Данные по почвам сохранены.')),
          );
        }
      },
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            Text('Почвы', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Выберите тип почвы и режим увлажнения участка.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSoilType,
                      decoration: _inputDecoration('Тип почвы'),
                      items: _soilTypes
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedSoilType = value);
                        if (value != null) {
                          context.read<SoilsBloc>().add(
                            SoilsEvent.typeChanged(value),
                          );
                        }
                      },
                      validator: (value) =>
                          value == null ? 'Выберите значение' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedMoisture,
                      decoration: _inputDecoration('Увлажнение'),
                      items: _moistureOptions
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedMoisture = value);
                        if (value != null) {
                          context.read<SoilsBloc>().add(
                            SoilsEvent.moistureChanged(value),
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
            BlocBuilder<SoilsBloc, SoilsState>(
              builder: (context, state) {
                final isLoading = state.status == SoilsStatus.loading;

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

  void _onSavePressed() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<SoilsBloc>().add(const SoilsEvent.saved());
    }
  }
}
