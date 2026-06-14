import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxation_card/features/di/widget/dependencies_scope.dart';
import 'package:taxation_card/features/home/bloc/main_tabs_bloc.dart';
import 'package:taxation_card/features/soils/domain/soils_repository.dart';

final class SoilsScreen extends StatefulWidget {
  const SoilsScreen({super.key});

  @override
  State<SoilsScreen> createState() => _SoilsScreenState();
}

final class _SoilsScreenState extends State<SoilsScreen>
    with AutomaticKeepAliveClientMixin {
  static const _soilTypeOptions = [
    'нет',
    'дерново-подзолистая',
    'дерново-карбонатная типичная',
    'светло-серая лесная',
    'серая лесная',
    'темносерая лесная',
    'чернозем оподзоленный',
    'чернозем выщелоченный',
    'чернозем типичный',
    'луговато-черноземовидная',
    'влажно-луговая',
    'лугово-болотная',
    'аллювиальная луговая',
    'аллювиальная лугово-болотная',
    'болотная низинная',
    'торфяно-болотная',
    'овражно-балочная',
    'деформированная',
    'торфяно-глеевые',
    'торфяные олиготрофные типичные обычные',
  ];
  static const _soilMoistureOptions = [
    'нет',
    'очень сухая',
    'сухая',
    'свежая',
    'влажная',
    'сырая',
    'мокрая',
  ];
  static const _soilDepthOptions = [
    'нет',
    'маломощная',
    'среднемощная',
    'мощная',
    'слабозакреп. пески',
    'слаборазвитые',
  ];
  static const _soilHorizonTextureOptions = [
    'нет',
    'песчаная',
    'супесчаная',
    'легкосуглинистая',
    'среднесуглинистая',
    'тяжелосуглинистая',
    'глинистая',
    'торф',
    'Органогенный материал',
  ];

  final _formKey = GlobalKey<FormState>();
  final _groundWaterLevelController = TextEditingController();
  final _litterSubhorizonController = TextEditingController();
  final _fermentativeLitterController = TextEditingController();
  final _humifiedLitterController = TextEditingController();
  final _peatyHumusController = TextEditingController();
  final _coarseHumusController = TextEditingController();
  final _humusController = TextEditingController();
  final _humusToEluvialTransitionController = TextEditingController();
  final _podzolicHorizonController = TextEditingController();
  final _secondHumusController = TextEditingController();
  final _classification1977Controller = TextEditingController();
  final _classification2004Controller = TextEditingController();
  final _wrb2015Controller = TextEditingController();
  final _noteController = TextEditingController();

  String? _soilType;
  String? _soilMoisture;
  String? _soilDepth;
  String? _upperSoilHorizon;
  String? _lowerSoilHorizon;
  Future<List<SoilRecord>>? _recordsFuture;
  int? _loadedProbaInfoId;
  bool _isSaving = false;
  final Set<int> _deletingIds = {};

  @override
  void dispose() {
    _groundWaterLevelController.dispose();
    _litterSubhorizonController.dispose();
    _fermentativeLitterController.dispose();
    _humifiedLitterController.dispose();
    _peatyHumusController.dispose();
    _coarseHumusController.dispose();
    _humusController.dispose();
    _humusToEluvialTransitionController.dispose();
    _podzolicHorizonController.dispose();
    _secondHumusController.dispose();
    _classification1977Controller.dispose();
    _classification2004Controller.dispose();
    _wrb2015Controller.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final selectedProbaInfoId = context.select<MainTabsBloc, int?>(
      (bloc) => bloc.state.selectedProbaInfoId,
    );
    _loadRecordsIfNeeded(selectedProbaInfoId);

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          Text('Почвы', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            selectedProbaInfoId == null
                ? 'Выберите пробную площадь для сохранения данных по почвам.'
                : 'Данные сохраняются для выбранной пробной площади.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                const _SectionHeader(title: 'Гранулометрический состав'),
                _DropdownRow(
                  label: 'Тип почв',
                  value: _soilType,
                  items: _soilTypeOptions,
                  onChanged: (value) {
                    setState(() => _soilType = value);
                  },
                ),
                _DropdownRow(
                  label: 'Влажность почвы',
                  value: _soilMoisture,
                  items: _soilMoistureOptions,
                  onChanged: (value) {
                    setState(() => _soilMoisture = value);
                  },
                ),
                _DropdownRow(
                  label: 'Мощность почвы',
                  value: _soilDepth,
                  items: _soilDepthOptions,
                  onChanged: (value) {
                    setState(() => _soilDepth = value);
                  },
                ),
                _DropdownRow(
                  label: 'Верхние почвенные горизонты',
                  value: _upperSoilHorizon,
                  items: _soilHorizonTextureOptions,
                  onChanged: (value) {
                    setState(() => _upperSoilHorizon = value);
                  },
                ),
                _DropdownRow(
                  label: 'Нижние почвенные горизонты',
                  value: _lowerSoilHorizon,
                  items: _soilHorizonTextureOptions,
                  onChanged: (value) {
                    setState(() => _lowerSoilHorizon = value);
                  },
                ),
                _TextInputRow(
                  label: 'Уровень грунтовых вод (верховодки), см',
                  controller: _groundWaterLevelController,
                  keyboardType: TextInputType.number,
                  validator: _validateNonNegativeNumber,
                ),
                const _SectionHeader(title: 'Мощность горизонта'),
                _TextInputRow(
                  label: 'Подгоризонт опада, см',
                  controller: _litterSubhorizonController,
                  keyboardType: TextInputType.number,
                  validator: _validateNonNegativeNumber,
                ),
                _TextInputRow(
                  label: 'Ферментативный горизонт подстилки, см',
                  controller: _fermentativeLitterController,
                  keyboardType: TextInputType.number,
                  validator: _validateNonNegativeNumber,
                ),
                _TextInputRow(
                  label: 'Гумифицированный слой подстилки, см',
                  controller: _humifiedLitterController,
                  keyboardType: TextInputType.number,
                  validator: _validateNonNegativeNumber,
                ),
                _TextInputRow(
                  label: 'Перегнойный и торфяный, см',
                  controller: _peatyHumusController,
                  keyboardType: TextInputType.number,
                  validator: _validateNonNegativeNumber,
                ),
                _TextInputRow(
                  label: 'Грубогумусовый, см',
                  controller: _coarseHumusController,
                  keyboardType: TextInputType.number,
                  validator: _validateNonNegativeNumber,
                ),
                _TextInputRow(
                  label: 'Гумусовый, см',
                  controller: _humusController,
                  keyboardType: TextInputType.number,
                  validator: _validateNonNegativeNumber,
                ),
                _TextInputRow(
                  label: 'Переходный от гумусового к элювиальному, см',
                  controller: _humusToEluvialTransitionController,
                  keyboardType: TextInputType.number,
                  validator: _validateNonNegativeNumber,
                ),
                _TextInputRow(
                  label: 'Подзолистый горизонт, см',
                  controller: _podzolicHorizonController,
                  keyboardType: TextInputType.number,
                  validator: _validateNonNegativeNumber,
                ),
                _TextInputRow(
                  label: 'Второй гумусовый, см',
                  controller: _secondHumusController,
                  keyboardType: TextInputType.number,
                  validator: _validateNonNegativeNumber,
                ),
                const _SectionHeader(title: 'Тип почвы'),
                _TextInputRow(
                  label: 'По классификации 1977 года',
                  controller: _classification1977Controller,
                ),
                _TextInputRow(
                  label: 'По классификации 2004 года',
                  controller: _classification2004Controller,
                ),
                _TextInputRow(
                  label: 'По международной классификации WRB 2015',
                  controller: _wrb2015Controller,
                ),
                const _SectionHeader(title: 'Примечание'),
                _TextInputRow(
                  label: 'Примечание',
                  controller: _noteController,
                  minLines: 2,
                  maxLines: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isSaving || selectedProbaInfoId == null
                ? null
                : () => _onSavePressed(selectedProbaInfoId),
            child: _isSaving
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : const Text('Сохранить'),
          ),
          const SizedBox(height: 16),
          _buildLatestRecords(selectedProbaInfoId),
        ],
      ),
    );
  }

  void _loadRecordsIfNeeded(int? selectedProbaInfoId) {
    if (_loadedProbaInfoId == selectedProbaInfoId) {
      return;
    }

    _loadedProbaInfoId = selectedProbaInfoId;
    _recordsFuture = selectedProbaInfoId == null
        ? null
        : DependenciesScope.of(
            context,
          ).soilsRepository.getLatestByProbaInfoId(selectedProbaInfoId);
  }

  Widget _buildLatestRecords(int? selectedProbaInfoId) {
    final recordsFuture = _recordsFuture;
    if (selectedProbaInfoId == null || recordsFuture == null) {
      return const _InfoCard(
        title: 'Список почв',
        message: 'Выберите пробную площадь, чтобы увидеть сохранённые записи.',
      );
    }

    return FutureBuilder<List<SoilRecord>>(
      future: recordsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return const _InfoCard(
            title: 'Список почв',
            message: 'Не удалось загрузить данные по почвам.',
          );
        }

        final records = snapshot.data ?? const [];
        if (records.isEmpty) {
          return const _InfoCard(
            title: 'Список почв',
            message: 'Сохранённых записей пока нет.',
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Список почв',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                for (var index = 0; index < records.length; index++) ...[
                  _SoilRecordTile(
                    record: records[index],
                    isDeleting: _deletingIds.contains(records[index].id),
                    onDeletePressed: () => _deleteRecord(records[index]),
                  ),
                  if (index != records.length - 1) const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;

  String? _validateNonNegativeNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Заполните поле';
    }

    final parsedValue = double.tryParse(value.trim().replaceAll(',', '.'));
    if (parsedValue == null) {
      return 'Введите число';
    }

    if (parsedValue < 0) {
      return 'Не меньше 0';
    }

    return null;
  }

  Future<void> _onSavePressed(int probaInfoId) async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      await DependenciesScope.of(context).soilsRepository.insert(
        SoilRecord(
          probaInfoId: probaInfoId,
          soilType: _soilType!,
          soilMoisture: _soilMoisture!,
          soilDepth: _soilDepth!,
          upperSoilHorizon: _upperSoilHorizon!,
          lowerSoilHorizon: _lowerSoilHorizon!,
          groundWaterLevel: _parseDouble(_groundWaterLevelController.text),
          litterSubhorizon: _parseDouble(_litterSubhorizonController.text),
          fermentativeLitter: _parseDouble(_fermentativeLitterController.text),
          humifiedLitter: _parseDouble(_humifiedLitterController.text),
          peatyHumus: _parseDouble(_peatyHumusController.text),
          coarseHumus: _parseDouble(_coarseHumusController.text),
          humus: _parseDouble(_humusController.text),
          humusToEluvialTransition: _parseDouble(
            _humusToEluvialTransitionController.text,
          ),
          podzolicHorizon: _parseDouble(_podzolicHorizonController.text),
          secondHumus: _parseDouble(_secondHumusController.text),
          classification1977: _classification1977Controller.text.trim(),
          classification2004: _classification2004Controller.text.trim(),
          wrb2015: _wrb2015Controller.text.trim(),
          note: _noteController.text.trim(),
        ),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Данные по почвам сохранены.')),
      );
      setState(() {
        _recordsFuture = DependenciesScope.of(
          context,
        ).soilsRepository.getLatestByProbaInfoId(probaInfoId);
      });
    } on Object {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось сохранить данные по почвам.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteRecord(SoilRecord record) async {
    final id = record.id;
    if (id == null) {
      return;
    }

    setState(() => _deletingIds.add(id));

    try {
      await DependenciesScope.of(context).soilsRepository.delete(id);
      if (!mounted) {
        return;
      }

      setState(() {
        _deletingIds.remove(id);
        _recordsFuture = DependenciesScope.of(
          context,
        ).soilsRepository.getLatestByProbaInfoId(record.probaInfoId);
      });
    } on Object {
      if (!mounted) {
        return;
      }

      setState(() => _deletingIds.remove(id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось удалить запись.')),
      );
    }
  }

  double _parseDouble(String value) {
    return double.parse(value.trim().replaceAll(',', '.'));
  }
}

final class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

final class _SoilRecordTile extends StatelessWidget {
  const _SoilRecordTile({
    required this.record,
    required this.isDeleting,
    required this.onDeletePressed,
  });

  final SoilRecord record;
  final bool isDeleting;
  final VoidCallback onDeletePressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(14);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: borderRadius,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Row(
          children: [
            ColoredBox(
              color: theme.colorScheme.primary,
              child: const SizedBox(width: 5, height: 52),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  [
                    record.soilType,
                    'Влажность: ${record.soilMoisture}',
                    'Мощность: ${record.soilDepth}',
                    'ГВ: ${_formatNumber(record.groundWaterLevel)} см',
                  ].join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: isDeleting ? null : onDeletePressed,
              icon: isDeleting
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : const Icon(Icons.delete_outline),
              tooltip: 'Удалить',
            ),
          ],
        ),
      ),
    );
  }
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value.toString();
}

final class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      color: const Color(0xFFC8E6C9),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: const Color(0xFF1B5E20),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

final class _DropdownRow extends StatelessWidget {
  const _DropdownRow({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SoilRow(
      label: label,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        ),
        items: items
            .map(
              (item) =>
                  DropdownMenuItem<String>(value: item, child: Text(item)),
            )
            .toList(),
        onChanged: onChanged,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Выберите значение';
          }

          return null;
        },
      ),
    );
  }
}

final class _TextInputRow extends StatelessWidget {
  const _TextInputRow({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.validator,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return _SoilRow(
      label: label,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: maxLines == 1 ? TextInputAction.next : null,
        minLines: minLines,
        maxLines: maxLines,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        ),
        validator: validator,
      ),
    );
  }
}

final class _SoilRow extends StatelessWidget {
  const _SoilRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.55)),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;

          if (compact) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 6),
                  child,
                ],
              ),
            );
          }

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(label, style: theme.textTheme.bodyMedium),
                    ),
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: theme.dividerColor.withValues(alpha: 0.55),
                ),
                Expanded(flex: 4, child: child),
              ],
            ),
          );
        },
      ),
    );
  }
}
