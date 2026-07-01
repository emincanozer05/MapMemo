import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      body: IndexedStack(index: _index, children: _screens),
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
