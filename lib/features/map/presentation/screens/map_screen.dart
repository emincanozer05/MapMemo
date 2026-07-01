import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../memory/domain/entities/memory.dart';
import '../../../memory/presentation/providers/memory_provider.dart';
import '../../../memory/presentation/screens/memory_detail_screen.dart';
import '../../../memory/presentation/widgets/add_memory_sheet.dart';

/// Interactive map: shows every saved memory as a marker, lets the user
/// long-press to drop a pending pin, and opens [AddMemorySheet] when that
/// pin is tapped.
///
/// The state is public ([MapScreenState]) so [HomeShell] can reach it
/// through a `GlobalKey` and call [focusOnMemory] when the user taps an
/// entry in the saved-places list.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(41.0082, 28.9784), // İstanbul
    zoom: 11,
  );

  GoogleMapController? _controller;
  LatLng? _pendingMarkerPosition;
  bool _myLocationEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _goToCurrentLocation());
  }

  Future<void> _goToCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      if (mounted) setState(() => _myLocationEnabled = true);

      final position = await Geolocator.getCurrentPosition();
      await _controller?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          14,
        ),
      );
    } catch (_) {
      // Konum alınamazsa varsayılan kamera konumunda kalınır.
    }
  }

  /// Animates the camera to [memory]'s location. Called from [HomeShell]
  /// when a saved place is tapped in the list tab.
  void focusOnMemory(Memory memory) {
    _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(memory.latitude, memory.longitude), 16),
    );
  }

  void _onLongPress(LatLng position) {
    setState(() => _pendingMarkerPosition = position);
  }

  Future<void> _openAddMemorySheet(LatLng position) async {
    await AddMemorySheet.show(context, position);
    if (!mounted) return;
    setState(() => _pendingMarkerPosition = null);
  }

  void _openMemoryDetail(Memory memory) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MemoryDetailScreen(memoryId: memory.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final memories = context.watch<MemoryProvider>().memories;

    final markers = <Marker>{
      for (final memory in memories)
        Marker(
          markerId: MarkerId(memory.id),
          position: LatLng(memory.latitude, memory.longitude),
          infoWindow: InfoWindow(
            title: memory.title,
            snippet: memory.note.isEmpty ? null : memory.note,
          ),
          onTap: () => _openMemoryDetail(memory),
        ),
      if (_pendingMarkerPosition case final pending?)
        Marker(
          markerId: const MarkerId('__pending__'),
          position: pending,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(
            title: 'Yeni anı',
            snippet: 'Formu açmak için dokun',
          ),
          onTap: () => _openAddMemorySheet(pending),
        ),
    };

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: _initialPosition,
          onMapCreated: (controller) => _controller = controller,
          onLongPress: _onLongPress,
          markers: markers,
          myLocationEnabled: _myLocationEnabled,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        ),
        Positioned(
          left: 16,
          right: 16,
          top: 16,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6),
                ],
              ),
              child: const Text(
                'Anı eklemek için haritada bir yere uzun basın, '
                'sonra beliren iğneye dokunun.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            heroTag: 'map-my-location',
            onPressed: _goToCurrentLocation,
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }
}
