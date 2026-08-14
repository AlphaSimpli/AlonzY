import 'dart:async';

import 'package:flutter/material.dart';

import '../maps/map_types.dart';
import '../services/geocoding_service.dart';
import '../theme/app_theme.dart';

/// Editable location input with live autocomplete suggestions.
///
/// Tapping the field focuses it immediately (opening the keyboard) and shows
/// address suggestions from the geocoding service as the user types. Selecting
/// a suggestion commits the address and reports the picked [MapLocation]
/// through [LocationAutocompleteField.onSelected]. Editing the text afterwards
/// clears the committed selection and fires [LocationAutocompleteField.onCleared].
///
/// This never navigates to a map view on its own; route previews are only
/// rendered by the parent screen once a valid place has been selected.
class LocationAutocompleteField extends StatefulWidget {
  const LocationAutocompleteField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.placeholder,
    this.focusNode,
    this.onSelected,
    this.onCleared,
    this.textInputAction = TextInputAction.next,
    this.autofocus = false,
    this.validator,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final IconData icon;
  final String placeholder;
  final void Function(MapLocation location, String address)? onSelected;
  final VoidCallback? onCleared;
  final TextInputAction textInputAction;
  final bool autofocus;
  final String? Function(String?)? validator;

  @override
  State<LocationAutocompleteField> createState() =>
      _LocationAutocompleteFieldState();
}

class _LocationAutocompleteFieldState extends State<LocationAutocompleteField> {
  final GeocodingService _geocoding = GeocodingService();

  Timer? _debounce;
  List<PlaceSuggestion> _suggestions = const [];
  bool _loadingSuggestions = false;

  /// Whether the current text is a committed address picked from the
  /// suggestions. Cleared whenever the user edits the text manually.
  bool _committed = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncCommitted);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_syncCommitted);
    super.dispose();
  }

  /// Keeps the committed state in sync when the parent swaps or edits the
  /// controller text programmatically.
  void _syncCommitted() {
    if (_committed && widget.controller.text != _selectedAddress) {
      _committed = false;
      widget.onCleared?.call();
    }
  }

  String? _selectedAddress;

  void _onChanged(String text) {
    _debounce?.cancel();

    if (text.trim().length < 3) {
      setState(() {
        _suggestions = const [];
        _loadingSuggestions = false;
      });
      return;
    }

    setState(() => _loadingSuggestions = true);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final results = await _geocoding.searchPlaces(text);
      if (!mounted || widget.controller.text.trim() != text.trim()) return;
      setState(() {
        _suggestions = results;
        _loadingSuggestions = false;
      });
    });
  }

  void _select(PlaceSuggestion suggestion) {
    _debounce?.cancel();
    _committed = true;
    _selectedAddress = suggestion.displayName;
    widget.controller.text = suggestion.displayName;
    widget.focusNode?.unfocus();
    setState(() => _suggestions = const []);
    widget.onSelected?.call(suggestion.location, suggestion.displayName);
  }

  void _clear() {
    _debounce?.cancel();
    _committed = false;
    _selectedAddress = null;
    widget.controller.clear();
    setState(() => _suggestions = const []);
    widget.onCleared?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          textInputAction: widget.textInputAction,
          onChanged: _onChanged,
          validator: widget.validator,
          decoration: InputDecoration(
            labelText: widget.label,
            prefixIcon: Icon(widget.icon),
            suffixIcon: _committed
                ? IconButton(
                    tooltip: 'Clear',
                    icon: const Icon(Icons.close),
                    onPressed: _clear,
                  )
                : const Icon(Icons.search),
            hintText: widget.placeholder,
          ),
        ),
        if (_loadingSuggestions)
          const LinearProgressIndicator(minHeight: 2)
        else if (_suggestions.isNotEmpty)
          Card(
            margin: const EdgeInsets.only(top: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < _suggestions.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.place_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      _suggestionTitle(_suggestions[i].displayName),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                    onTap: () => _select(_suggestions[i]),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  /// Shortens a full display name to the part that follows the first comma,
  /// keeping the field readable (e.g. "Montreal, QC, Canada").
  String _suggestionTitle(String displayName) {
    final parts = displayName.split(',');
    if (parts.length > 2) return parts.sublist(0, 2).join(',').trim();
    return displayName;
  }
}
