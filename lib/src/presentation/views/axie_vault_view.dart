// ===============================================================================
// [MODULE_NAME]: axie_vault_view.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Presentation / Views
// [INTENT]: Renders the Axie Importer interface over the atmospheric backdrop.
// [DEPENDENCIES]: package:flutter/material.dart, package:flutter_riverpod/flutter_riverpod.dart, ../controllers/axie_importer_controller.dart, ../controllers/app_navigation_controller.dart, widgets/axie_card_standee.dart, widgets/atmospheric_battlefield_backdrop.dart
// [ARCHITECTURE]: Riverpod ConsumerStatefulWidget
// ===============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/axie_importer_controller.dart';
import '../controllers/app_navigation_controller.dart';
import 'widgets/axie_card_standee.dart';
import 'widgets/atmospheric_battlefield_backdrop.dart';

class AxieVaultView extends ConsumerStatefulWidget {
  const AxieVaultView({super.key});

  @override
  ConsumerState<AxieVaultView> createState() => _AxieVaultViewState();
}

class _AxieVaultViewState extends ConsumerState<AxieVaultView> {
  late final TextEditingController _inputController;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _submit() {
    ref.read(axieImporterProvider.notifier).processImportInput(_inputController.text);
  }

  @override
  Widget build(BuildContext context) {
    final importState = ref.watch(axieImporterProvider);

    return AtmosphericBattlefieldBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.arrow_back, color: Colors.amber),
                    label: const Text('Return to Menu', style: TextStyle(color: Colors.amber)),
                    onPressed: () => ref.read(appNavigationProvider.notifier).returnToMainMenu(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      decoration: const InputDecoration(
                        hintText: 'Enter Ronin wallet or Axie IDs',
                        border: OutlineInputBorder(),
                        fillColor: Colors.white10,
                        filled: true,
                      ),
                      style: const TextStyle(color: Colors.white),
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Import'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: importState.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Colors.amber),
                  ),
                  error: (err, st) => Center(
                    child: Text(
                      'Error: $err',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                  data: (axies) {
                    if (axies.isEmpty) {
                      return const Center(
                        child: Text(
                          'No Axies imported yet. Enter a wallet or IDs above.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }

                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 250,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: axies.length,
                      itemBuilder: (context, index) {
                        return AxieCardStandee(axie: axies[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
