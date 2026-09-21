// ===============================================================================
// [MODULE_NAME]: axie_vault_view.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Presentation / Views
// [INTENT]: Sovereign Axie Vault management with on-chain import, resilient offline fallback, and persistent local storage synchronization.
// [DEPENDENCIES]: package:flutter/material.dart, package:flutter_riverpod/flutter_riverpod.dart, ../controllers/axie_importer_controller.dart, ../controllers/axie_vault_controller.dart, ../controllers/app_navigation_controller.dart, ../widgets/axie_creature_card_view.dart, widgets/atmospheric_battlefield_backdrop.dart
// [ARCHITECTURE]: Riverpod ConsumerStatefulWidget
// ===============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/axie_card_entity.dart';
import '../controllers/axie_importer_controller.dart';
import '../controllers/axie_vault_controller.dart';
import '../controllers/app_navigation_controller.dart';
import '../widgets/axie_creature_card_view.dart';
import 'widgets/atmospheric_battlefield_backdrop.dart';

class AxieVaultView extends ConsumerStatefulWidget {
  const AxieVaultView({super.key});

  @override
  ConsumerState<AxieVaultView> createState() => _AxieVaultViewState();
}

class _AxieVaultViewState extends ConsumerState<AxieVaultView> {
  late final TextEditingController _inputController;
  int _activeTabIndex = 0; // 0: Saved Vault, 1: Imported Discoveries

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
    final query = _inputController.text.trim();
    if (query.isNotEmpty) {
      setState(() => _activeTabIndex = 1);
      ref.read(axieImporterProvider.notifier).processImportInput(query);
    }
  }

  void _loadDemoSquad() {
    setState(() => _activeTabIndex = 1);
    ref.read(axieImporterProvider.notifier).processImportInput('1,2,3');
  }

  @override
  Widget build(BuildContext context) {
    final importState = ref.watch(axieImporterProvider);
    final isOffline = ref.watch(axieImporterProvider.notifier).isOfflineFallback;
    final vaultAsync = ref.watch(savedAxiesVaultProvider);
    final savedAxies = vaultAsync.valueOrNull ?? [];

    return AtmosphericBattlefieldBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Navigation & Header
                Row(
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.arrow_back, color: Colors.amber),
                      label: const Text('Return to Menu', style: TextStyle(color: Colors.amber)),
                      onPressed: () => ref.read(appNavigationProvider.notifier).returnToMainMenu(),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'LUNACIAN AXIE VAULT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6CC000).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF6CC000)),
                      ),
                      child: Text(
                        'Saved: ${savedAxies.length} Axies',
                        style: const TextStyle(
                          color: Color(0xFF6CC000),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 2. Search & Import Toolbar
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        decoration: const InputDecoration(
                          hintText: 'Enter Ronin wallet or Axie IDs (e.g. 1, 2, 3)',
                          border: OutlineInputBorder(),
                          fillColor: Colors.white10,
                          filled: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Import'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onPressed: _submit,
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.offline_bolt, size: 16, color: Colors.cyanAccent),
                      label: const Text('Demo Squad', style: TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.cyanAccent),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      ),
                      onPressed: _loadDemoSquad,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 3. Offline / Demo Mode Banner (AC-01)
                if (isOffline)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade900.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amberAccent),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.wifi_off, color: Colors.amberAccent, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Offline/Demo mode: Loaded local Lunacian squad',
                            style: TextStyle(
                              color: Colors.amberAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 4. Tab Selector (Saved Vault vs Imported Results)
                Row(
                  children: [
                    _buildTabChip(
                      index: 0,
                      label: 'SAVED IN VAULT (${savedAxies.length})',
                      icon: Icons.inventory_2,
                      activeColor: const Color(0xFF6CC000),
                    ),
                    const SizedBox(width: 8),
                    _buildTabChip(
                      index: 1,
                      label: 'IMPORTED DISCOVERIES',
                      icon: Icons.travel_explore,
                      activeColor: Colors.amberAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 5. Active Tab View
                Expanded(
                  child: _activeTabIndex == 0
                      ? _buildSavedVaultView(savedAxies)
                      : _buildImportedResultsView(importState, savedAxies),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabChip({
    required int index,
    required String label,
    required IconData icon,
    required Color activeColor,
  }) {
    final isSelected = _activeTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.2) : Colors.white10,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? activeColor : Colors.white24,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? activeColor : Colors.white70),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedVaultView(List<AxieCardEntity> savedAxies) {
    if (savedAxies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            const Text(
              'No Axies saved in your Vault yet.',
              style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Import creatures above or tap "Demo Squad", then click "SAVE TO VAULT".\nSaved Axies appear directly inside the Deck Builder!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.offline_bolt, size: 16),
              label: const Text('Load Demo Squad'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              onPressed: _loadDemoSquad,
            ),
          ],
        ),
      );
    }

    return _buildAxieGrid(savedAxies, savedAxies);
  }

  Widget _buildImportedResultsView(
    AsyncValue<List<AxieCardEntity>> importState,
    List<AxieCardEntity> savedAxies,
  ) {
    return importState.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Colors.amber),
      ),
      error: (err, st) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
            const SizedBox(height: 8),
            Text(
              'Failed to import: $err',
              style: const TextStyle(color: Colors.redAccent),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadDemoSquad,
              child: const Text('Load Offline Demo Squad Instead'),
            ),
          ],
        ),
      ),
      data: (axies) {
        if (axies.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search, size: 48, color: Colors.white.withValues(alpha: 0.3)),
                const SizedBox(height: 12),
                const Text(
                  'No Axies imported yet. Enter a wallet or IDs above.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.offline_bolt, size: 16),
                  label: const Text('Load Demo Squad (Buba, Olek, Puffy)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: _loadDemoSquad,
                ),
              ],
            ),
          );
        }

        return _buildAxieGrid(axies, savedAxies);
      },
    );
  }

  Widget _buildAxieGrid(List<AxieCardEntity> displayAxies, List<AxieCardEntity> savedAxies) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        childAspectRatio: 0.58,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: displayAxies.length,
      itemBuilder: (context, index) {
        final axie = displayAxies[index];
        final isSaved = savedAxies.any((a) => a.id == axie.id);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: CardWarsCardView(axie: axie),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: isSaved
                  ? OutlinedButton.icon(
                      icon: const Icon(Icons.bookmark_remove, size: 13, color: Colors.redAccent),
                      label: const Text('REMOVE', style: TextStyle(fontSize: 10, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                      ),
                      onPressed: () async {
                        await ref.read(savedAxiesVaultProvider.notifier).toggleSaveAxie(axie);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Removed ${axie.name} from Vault.'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    )
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.bookmark_add, size: 13, color: Colors.black),
                      label: const Text('SAVE TO VAULT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                      ),
                      onPressed: () async {
                        await ref.read(savedAxiesVaultProvider.notifier).toggleSaveAxie(axie);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Saved ${axie.name} to Vault!'),
                              backgroundColor: Colors.teal.shade800,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
