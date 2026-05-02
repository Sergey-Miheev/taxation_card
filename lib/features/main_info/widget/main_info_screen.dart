import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxation_card/core/database/seed_data.dart';
import 'package:taxation_card/features/home/bloc/main_tabs_bloc.dart';
import 'package:taxation_card/features/main_info/bloc/main_info_bloc.dart';
import 'package:taxation_card/features/taxation_characteristic/widget/taxation_characteristic_screen.dart';

final class MainInfoScreen extends StatefulWidget {
  const MainInfoScreen({super.key});

  @override
  State<MainInfoScreen> createState() => _MainInfoScreenState();
}

final class _MainInfoScreenState extends State<MainInfoScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _quarterController = TextEditingController();
  final TextEditingController _allotmentController = TextEditingController();
  final TextEditingController _samplePlotNumberController =
      TextEditingController();
  final TextEditingController _samplePlotAreaController =
      TextEditingController();
  final TextEditingController _forestryController = TextEditingController();
  final TextEditingController _subForestryController = TextEditingController();

  late final MainInfoBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = context.read<MainInfoBloc>();
    _syncControllers(_bloc.state.data);
    _quarterController.addListener(_onQuarterChanged);
    _allotmentController.addListener(_onAllotmentChanged);
    _samplePlotNumberController.addListener(_onSamplePlotNumberChanged);
    _samplePlotAreaController.addListener(_onSamplePlotAreaChanged);
    _forestryController.addListener(_onForestryChanged);
    _subForestryController.addListener(_onSubForestryChanged);
  }

  @override
  void dispose() {
    _quarterController.removeListener(_onQuarterChanged);
    _allotmentController.removeListener(_onAllotmentChanged);
    _samplePlotNumberController.removeListener(_onSamplePlotNumberChanged);
    _samplePlotAreaController.removeListener(_onSamplePlotAreaChanged);
    _forestryController.removeListener(_onForestryChanged);
    _subForestryController.removeListener(_onSubForestryChanged);
    _quarterController.dispose();
    _allotmentController.dispose();
    _samplePlotNumberController.dispose();
    _samplePlotAreaController.dispose();
    _forestryController.dispose();
    _subForestryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return BlocListener<MainInfoBloc, MainInfoState>(
      listenWhen: (previous, current) =>
          previous.status != current.status || previous.data != current.data,
      listener: (context, state) {
        _syncControllers(state.data);

        switch (state.status) {
          case MainInfoSubmissionStatus.success:
            context.read<MainTabsBloc>().add(
              const MainTabsEvent.tabSelected(MainTab.permanentPp),
            );
          case MainInfoSubmissionStatus.failure:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message ?? 'Не удалось отправить данные.'),
              ),
            );
          case MainInfoSubmissionStatus.idle:
          case MainInfoSubmissionStatus.loading:
            break;
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 720;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 24 : 16,
              vertical: 16,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Общая информация',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Заполните местоположение и параметры пробной площади.',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    if (isTablet)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildLocationCard()),
                          const SizedBox(width: 16),
                          Expanded(child: _buildSamplePlotCard()),
                        ],
                      )
                    else ...[
                      _buildLocationCard(),
                      const SizedBox(height: 12),
                      _buildSamplePlotCard(),
                    ],
                    const SizedBox(height: 16),
                    _buildAddButton(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  void _syncControllers(MainInfoFormData data) {
    _setControllerText(_quarterController, data.quarter.toString());
    _setControllerText(_allotmentController, data.allotment.toString());
    _setControllerText(
      _samplePlotNumberController,
      data.samplePlotNumber.toString(),
    );
    _setControllerText(
      _samplePlotAreaController,
      data.samplePlotArea.toString(),
    );
    _setControllerText(_forestryController, data.forestry ?? '');
    _setControllerText(_subForestryController, data.subForestry ?? '');
  }

  void _setControllerText(TextEditingController controller, String text) {
    if (controller.text == text) {
      return;
    }

    controller.value = controller.value.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
      composing: TextRange.empty,
    );
  }

  void _onQuarterChanged() {
    _bloc.add(MainInfoEvent.quarterChanged(_quarterController.text));
  }

  void _onAllotmentChanged() {
    _bloc.add(MainInfoEvent.allotmentChanged(_allotmentController.text));
  }

  void _onSamplePlotNumberChanged() {
    _bloc.add(
      MainInfoEvent.samplePlotNumberChanged(_samplePlotNumberController.text),
    );
  }

  void _onSamplePlotAreaChanged() {
    _bloc.add(
      MainInfoEvent.samplePlotAreaChanged(_samplePlotAreaController.text),
    );
  }

  void _onForestryChanged() {
    _bloc.add(MainInfoEvent.forestryChanged(_forestryController.text));
  }

  void _onSubForestryChanged() {
    _bloc.add(MainInfoEvent.subForestryChanged(_subForestryController.text));
  }

  Widget _buildLocationCard() {
    return BlocBuilder<MainInfoBloc, MainInfoState>(
      buildWhen: (previous, current) => previous.data != current.data,
      builder: (context, state) => _SectionCard(
        title: 'Местоположение',
        child: Column(
          children: [
            _buildResponsiveFields(
              children: [
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: state.data.region,
                  decoration: _inputDecoration(labelText: 'Субъект РФ'),
                  items: russianFederationData.keys
                      .toList()
                      .map(
                        (region) => DropdownMenuItem(
                          value: region,
                          child: Text(region, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (regionValue) {
                    context.read<MainInfoBloc>().add(
                      MainInfoEvent.regionChanged(regionValue),
                    );
                  },
                ),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: state.data.district,
                  decoration: _inputDecoration(
                    labelText: 'Муниципальный район',
                  ),
                  items: russianFederationData[state.data.region]
                      ?.toList()
                      .map(
                        (district) => DropdownMenuItem(
                          value: district,
                          child: Text(
                            district,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (districtValue) {
                    context.read<MainInfoBloc>().add(
                      MainInfoEvent.districtChanged(districtValue),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildResponsiveFields(
              children: [
                TextField(
                  controller: _forestryController,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    labelText: 'Районное лесничество',
                  ),
                ),
                TextField(
                  controller: _subForestryController,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    labelText: 'Участковое лесничество',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSamplePlotCard() {
    return _SectionCard(
      title: 'Пробная площадь',
      child: _buildResponsiveFields(
        children: [
          TextField(
            controller: _quarterController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(labelText: 'Квартал'),
          ),
          TextField(
            controller: _allotmentController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(labelText: 'Выдел'),
          ),
          TextField(
            controller: _samplePlotNumberController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(labelText: 'Номер пробной площади'),
          ),
          TextField(
            controller: _samplePlotAreaController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _inputDecoration(labelText: 'Площадь ПП'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => const TaxationCharacteristicScreen(),
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text('Добавить'),
      ),
    );
  }

  InputDecoration _inputDecoration({required String labelText}) {
    return InputDecoration(
      labelText: labelText,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1.4,
        ),
      ),
    );
  }

  Widget _buildResponsiveFields({required List<Widget> children}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 520;
        if (!isWide) {
          return Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              Expanded(child: children[i]),
              if (i != children.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }
}

final class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

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
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
