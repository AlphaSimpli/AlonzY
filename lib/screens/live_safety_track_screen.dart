import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/generated/app_localizations.dart';
import '../maps/app_maps.dart';
import '../maps/map_controller.dart';
import '../maps/map_types.dart';
import '../models/live_ride_location.dart';
import '../services/live_safety_service.dart';
import '../services/osrm_service.dart';
import '../services/safety_tracking_service.dart';

class LiveSafetyTrackScreen extends StatefulWidget {
  const LiveSafetyTrackScreen({
    required this.bookingId,
    required this.rideId,
    required this.start,
    required this.end,
    required this.startLabel,
    required this.endLabel,
    super.key,
  });

  final String bookingId;
  final String rideId;
  final MapLocation start;
  final MapLocation end;
  final String startLabel;
  final String endLabel;

  @override
  State<LiveSafetyTrackScreen> createState() => _LiveSafetyTrackScreenState();
}

class _LiveSafetyTrackScreenState extends State<LiveSafetyTrackScreen> {
  final LiveSafetyService _liveSafetyService = LiveSafetyService();
  final SafetyTrackingService _publicSafetyService = SafetyTrackingService();
  final OsrmService _osrmService = OsrmService();
  final Map<String, LiveRideLocation> _locations = {};
  AppMapController? _mapController;
  RealtimeChannel? _locationChannel;
  StreamSubscription<Position>? _positionSubscription;
  Uri? _shareUrl;
  MapLocation? _myPosition;
  bool _isInternalSharing = false;
  bool _isPublicSharing = false;
  bool _isStartingShare = false;
  bool _isDisposed = false;
  String? _errorMessage;

  bool get _isSharing => _isInternalSharing && _isPublicSharing;

  @override
  void dispose() {
    _isDisposed = true;
    final channel = _locationChannel;
    if (channel != null) unawaited(_unsubscribeChannel(channel));
    _locationChannel = null;
    unawaited(_stopSharingOnDispose());
    unawaited(_positionSubscription?.cancel());
    _positionSubscription = null;
    _osrmService.close();
    _mapController?.dispose();
    _mapController = null;
    super.dispose();
  }

  Future<void> _unsubscribeChannel(RealtimeChannel channel) async {
    try {
      await channel.unsubscribe();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'Live Safety Track',
          context: ErrorDescription('while unsubscribing from ride locations'),
        ),
      );
    }
  }

  Future<void> _stopSharingOnDispose() async {
    try {
      await _liveSafetyService.stopSharing();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'Live Safety Track',
          context: ErrorDescription('while stopping participant sharing'),
        ),
      );
    }
    try {
      await _publicSafetyService.stopSharing();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'Live Safety Track',
          context: ErrorDescription('while revoking the public safety link'),
        ),
      );
    }
  }

  void _onMapCreated(AppMapController controller) {
    if (!mounted || _isDisposed) {
      controller.dispose();
      return;
    }
    _mapController = controller;
    _locationChannel = _liveSafetyService.subscribeToRideLocations(
      rideId: widget.rideId,
      onLocation: _showLocation,
      onLocationRemoved: _removeLocation,
      onError: _showError,
    );
    unawaited(_initializeMap(controller));
  }

  Future<void> _initializeMap(AppMapController controller) async {
    final strings = AppLocalizations.of(context);
    try {
      List<MapLocation> routePoints;
      try {
        final route = await _osrmService.getRoute([
          OsrmCoordinate(widget.start.latitude, widget.start.longitude),
          OsrmCoordinate(widget.end.latitude, widget.end.longitude),
        ], includeGeometry: true);
        routePoints = route.geometry
            .map((point) => MapLocation(point.latitude, point.longitude))
            .toList(growable: false);
      } catch (error) {
        debugPrint('OSRM route unavailable; showing direct fallback: $error');
        routePoints = [widget.start, widget.end];
      }
      if (!mounted || _isDisposed) return;
      await controller.addStyledPolyline(
        MapPolylineData(
          points: routePoints,
          colorHex: '#1E3A8A',
          width: 7,
          opacity: 0.45,
          lineCap: 'round',
          lineJoin: 'round',
        ),
      );
      await controller.addStyledPolyline(
        MapPolylineData(
          points: routePoints,
          colorHex: '#3B82F6',
          width: 4.5,
          lineCap: 'round',
          lineJoin: 'round',
        ),
      );
      await controller.addCircleMarker(
        MapMarkerData(
          id: 'ride-start',
          location: widget.start,
          label: '${strings.safetyTrackingStartLabel}: ${widget.startLabel}',
          colorHex: '#10B981',
          circleRadius: 8,
          circleStrokeColor: '#FFFFFF',
          circleStrokeWidth: 3,
        ),
      );
      await controller.addCircleMarker(
        MapMarkerData(
          id: 'ride-end',
          location: widget.end,
          label: '${strings.safetyTrackingEndLabel}: ${widget.endLabel}',
          colorHex: '#EF4444',
          circleRadius: 8,
          circleStrokeColor: '#FFFFFF',
          circleStrokeWidth: 3,
        ),
      );
      if (!mounted || _isDisposed) return;
      final currentPosition = await _loadCurrentPosition();
      final visiblePoints = [...routePoints, ?currentPosition];
      await controller.animateToBoundsWithPadding(
        visiblePoints,
        left: 56,
        top: 72,
        right: 56,
        bottom: 320,
      );
    } catch (error, stackTrace) {
      _showError(error, stackTrace);
    }
  }

  Future<MapLocation?> _loadCurrentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('Location services are disabled.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        throw StateError('Location permission is required.');
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted || _isDisposed) return null;
      final location = MapLocation(position.latitude, position.longitude);
      await _showMyPosition(position);
      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 0,
            ),
          ).listen(
            (fix) => unawaited(_showMyPosition(fix)),
            onError: (Object error, StackTrace stackTrace) {
              _showError(error, stackTrace);
            },
          );
      return location;
    } catch (error, stackTrace) {
      _showError(error, stackTrace);
      return null;
    }
  }

  Future<void> _showMyPosition(Position position) async {
    if (!mounted || _isDisposed) return;
    final location = MapLocation(position.latitude, position.longitude);
    setState(() {
      _myPosition = location;
      _errorMessage = null;
    });
    final controller = _mapController;
    if (controller == null) return;
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      await controller.addMarker(
        MapMarkerData(
          id: userId ?? 'current-user-position',
          location: location,
          label: AppLocalizations.of(context).safetyTrackingMyPosition,
          colorHex: '#4F46E5',
        ),
      );
    } catch (error, stackTrace) {
      _showError(error, stackTrace);
    }
  }

  void _showLocation(LiveRideLocation location) {
    if (!mounted || _isDisposed) return;
    final previous = _locations[location.userId];
    if (previous != null && !location.capturedAt.isAfter(previous.capturedAt)) {
      return;
    }
    setState(() {
      _locations[location.userId] = location;
      _errorMessage = null;
    });
    unawaited(_updateParticipantMarker(location));
  }

  Future<void> _updateParticipantMarker(LiveRideLocation location) async {
    final controller = _mapController;
    if (!mounted || _isDisposed || controller == null) return;
    try {
      final isMe =
          location.userId == Supabase.instance.client.auth.currentUser?.id;
      await controller.addMarker(
        MapMarkerData(
          id: location.userId,
          location: MapLocation(location.latitude, location.longitude),
          label: isMe
              ? AppLocalizations.of(context).safetyTrackingMyPosition
              : AppLocalizations.of(context).safetyTrackingParticipant,
          colorHex: isMe ? '#4F46E5' : '#10B981',
        ),
      );
    } catch (error, stackTrace) {
      _showError(error, stackTrace);
    }
  }

  void _removeLocation(String userId) {
    if (!mounted || _isDisposed) return;
    setState(() => _locations.remove(userId));
    unawaited(_mapController?.removeMarker(userId));
  }

  void _showError(Object error, StackTrace stackTrace) {
    if (!mounted || _isDisposed) return;
    setState(() {
      _errorMessage = error is StateError || error is PermissionDeniedException
          ? AppLocalizations.of(context).safetyTrackingLocationUnavailable
          : AppLocalizations.of(context).safetyShareFailed;
    });
  }

  Future<void> _toggleSharing() async {
    if (!mounted || _isDisposed || _isStartingShare) return;
    if (_isSharing) {
      await _stopSharing();
      return;
    }
    final strings = AppLocalizations.of(context);
    final consent = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.safetyConsentTitle),
        content: Text(strings.safetyConsentMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(strings.safetyCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(strings.safetyStartSharing),
          ),
        ],
      ),
    );
    if (!mounted || _isDisposed || consent != true) return;

    setState(() {
      _isStartingShare = true;
      _errorMessage = null;
    });
    try {
      await _liveSafetyService.startSharing(
        rideId: widget.rideId,
        onError: _showError,
      );
      _isInternalSharing = true;
      final link = await _publicSafetyService.startSharing(
        bookingId: widget.bookingId,
        rideId: widget.rideId,
        consentGiven: true,
        invokeShareSheet: false,
        onError: _showError,
      );
      _isPublicSharing = true;
      if (!mounted || _isDisposed) {
        await _stopSharingOnDispose();
        return;
      }
      setState(() => _shareUrl = link);
      _showSnackBar(strings.safetySharingStarted);
    } catch (error, stackTrace) {
      await _stopSharingOnDispose();
      _isInternalSharing = false;
      _isPublicSharing = false;
      _shareUrl = null;
      _showError(error, stackTrace);
    } finally {
      if (mounted && !_isDisposed) {
        setState(() => _isStartingShare = false);
      }
    }
  }

  Future<void> _stopSharing() async {
    if (!mounted || _isDisposed) return;
    setState(() => _isStartingShare = true);
    Object? stopError;
    try {
      await _liveSafetyService.stopSharing();
    } catch (error) {
      stopError = error;
    }
    try {
      await _publicSafetyService.stopSharing();
    } catch (error) {
      stopError ??= error;
    }
    if (!mounted || _isDisposed) return;
    setState(() {
      _isInternalSharing = false;
      _isPublicSharing = false;
      _isStartingShare = false;
      _shareUrl = null;
      if (stopError != null) {
        _errorMessage = AppLocalizations.of(context).safetyShareFailed;
      }
    });
    if (stopError == null) {
      _showSnackBar(AppLocalizations.of(context).safetySharingStopped);
    }
  }

  Future<void> _copyShareLink() async {
    final link = _shareUrl;
    if (link == null) return;
    await Clipboard.setData(ClipboardData(text: link.toString()));
    if (mounted && !_isDisposed) {
      _showSnackBar(AppLocalizations.of(context).safetyTrackingLinkCopied);
    }
  }

  Future<void> _sendShareLink() async {
    final link = _shareUrl;
    if (link == null) return;
    await SharePlus.instance.share(ShareParams(text: link.toString()));
  }

  void _recenter() {
    final location = _myPosition;
    if (location != null) unawaited(_mapController?.animateTo(location));
  }

  void _showSnackBar(String message) {
    if (!mounted || _isDisposed) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.safetyTrackingTitle)),
      body: Stack(
        children: [
          Positioned.fill(
            child: AppMaps.createView(
              MapViewConfig(
                initialCenter: widget.start,
                initialZoom: 12,
                showUserLocation: false,
              ),
            ).build(onMapCreated: _onMapCreated),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton.small(
              tooltip: strings.safetyTrackingRecenter,
              onPressed: _recenter,
              child: const Icon(Icons.my_location),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      strings.safetyTrackingParticipants(_locations.length),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSharing
                          ? strings.safetyTrackingVisibleBy
                          : strings.safetyTrackingNotSharing,
                    ),
                    if (_shareUrl case final url?) ...[
                      const SizedBox(height: 8),
                      SelectableText(url.toString()),
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.spaceEvenly,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _copyShareLink,
                            icon: const Icon(Icons.copy),
                            label: Text(strings.safetyTrackingCopyLink),
                          ),
                          OutlinedButton.icon(
                            onPressed: _sendShareLink,
                            icon: const Icon(Icons.send),
                            label: Text(strings.safetyTrackingSendLink),
                          ),
                        ],
                      ),
                    ],
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _isStartingShare ? null : _toggleSharing,
                      icon: _isStartingShare
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              _isSharing
                                  ? Icons.location_off
                                  : Icons.share_location,
                            ),
                      label: Text(
                        _isSharing
                            ? strings.safetyStopSharing
                            : strings.safetyTrackingStart,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
