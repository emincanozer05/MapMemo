import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/connectivity/connectivity_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../map/presentation/screens/map_screen.dart';
import '../../../memory/domain/entities/memory.dart';
import '../../../memory/presentation/screens/memory_list_screen.dart';

/// Bottom-navigation shell shown once the user is authenticated. Switches
/// between the map and the saved-places list without losing either
/// screen's state (kept alive via [IndexedStack]).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final GlobalKey<MapScreenState> _mapKey = GlobalKey<MapScreenState>();

  late final List<Widget> _screens = [
    MapScreen(key: _mapKey),
    MemoryListScreen(onMemorySelected: _focusMemoryOnMap),
  ];

  static const List<String> _titles = ['Harita', 'Kaydedilenler'];

  void _focusMemoryOnMap(Memory memory) {
    setState(() => _index = 0);
    // Wait for the IndexedStack to show the map tab before moving the
    // camera, otherwise the animation runs on a screen that isn't visible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapKey.currentState?.focusOnMemory(memory);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isOnline = context.watch<ConnectivityProvider>().isOnline;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          if (user?.photoUrl != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(user!.photoUrl!),
              ),
            ),
          IconButton(
            tooltip: 'Çıkış Yap',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!isOnline) const _OfflineBanner(),
          Expanded(
            child: IndexedStack(index: _index, children: _screens),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Harita',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Kayıtlarım',
          ),
        ],
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.amber.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.cloud_off, size: 18, color: Colors.amber.shade900),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Çevrimdışısın. Kayıtlı anılarını görebilirsin; '
              'yeni değişiklikler bağlantı gelince eşitlenecek.',
              style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
            ),
          ),
        ],
      ),
    );
  }
}
