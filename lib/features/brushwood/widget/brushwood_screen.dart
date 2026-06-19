import 'package:flutter/material.dart';

final class BrushwoodScreen extends StatefulWidget {
  const BrushwoodScreen({super.key});

  @override
  State<BrushwoodScreen> createState() => _BrushwoodScreenState();
}

final class _BrushwoodScreenState extends State<BrushwoodScreen>
    with AutomaticKeepAliveClientMixin {
  final _brushwoodPercentController = TextEditingController();

  @override
  void dispose() {
    _brushwoodPercentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        TextFormField(
          controller: _brushwoodPercentController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Процент хвороста',
            suffixText: '%',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
