// Multi-Select Floating Dropdown Component (Anchored Overlay with Checkmarks)
// File: lib/core/widgets/multi_select_dropdown.dart

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// FormField wrapper for multi-select dropdown with anchored floating overlay & checkmarks
class MultiSelectDropdownFormField<T> extends FormField<List<T>> {
  final List<T> items;
  final String Function(T) itemLabel;
  final bool Function(T item, String query)? searchMatcher;
  final ValueChanged<List<T>>? onChanged;
  final String? hintText;
  final String title;
  final bool isLoading;
  final List<T>? value;

  MultiSelectDropdownFormField({
    super.key,
    required this.items,
    required this.itemLabel,
    this.searchMatcher,
    this.onChanged,
    this.value,
    List<T>? initialValue,
    super.validator,
    this.hintText = 'Select',
    this.title = 'Select Items',
    this.isLoading = false,
  }) : super(
          initialValue: value ?? initialValue ?? [],
          builder: (FormFieldState<List<T>> state) {
            final effectiveValues = value ?? state.value ?? [];
            return _MultiSelectDropdownWidget<T>(
              items: items,
              itemLabel: itemLabel,
              searchMatcher: searchMatcher,
              selectedValues: effectiveValues,
              onChanged: (newValues) {
                state.didChange(newValues);
                onChanged?.call(newValues);
              },
              hintText: hintText,
              title: title,
              isLoading: isLoading,
              errorText: state.errorText,
            );
          },
        );
}

class _MultiSelectDropdownWidget<T> extends StatefulWidget {
  final List<T> items;
  final String Function(T) itemLabel;
  final bool Function(T item, String query)? searchMatcher;
  final List<T> selectedValues;
  final ValueChanged<List<T>> onChanged;
  final String? hintText;
  final String title;
  final bool isLoading;
  final String? errorText;

  const _MultiSelectDropdownWidget({
    required this.items,
    required this.itemLabel,
    this.searchMatcher,
    required this.selectedValues,
    required this.onChanged,
    this.hintText,
    required this.title,
    this.isLoading = false,
    this.errorText,
  });

  @override
  State<_MultiSelectDropdownWidget<T>> createState() =>
      _MultiSelectDropdownWidgetState<T>();
}

class _MultiSelectDropdownWidgetState<T>
    extends State<_MultiSelectDropdownWidget<T>> {
  final LayerLink _layerLink = LayerLink();
  late final ValueNotifier<List<T>> _selectedNotifier;
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _selectedNotifier = ValueNotifier<List<T>>(List<T>.from(widget.selectedValues));
  }

  @override
  void didUpdateWidget(covariant _MultiSelectDropdownWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _selectedNotifier.value = List<T>.from(widget.selectedValues);
  }

  @override
  void dispose() {
    _closeDropdown(markState: false);
    _selectedNotifier.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    if (widget.isLoading || widget.items.isEmpty) return;
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    FocusScope.of(context).unfocus();
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
  }

  void _closeDropdown({bool markState = true}) {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (markState && mounted) {
      setState(() {
        _isOpen = false;
      });
    }
  }

  bool _isItemSelected(List<T> currentList, T item) {
    final label = widget.itemLabel(item);
    return currentList.any((s) => s == item || widget.itemLabel(s) == label);
  }

  void _toggleItem(T item) {
    final current = List<T>.from(_selectedNotifier.value);
    final label = widget.itemLabel(item);
    final existingIndex = current.indexWhere(
      (s) => s == item || widget.itemLabel(s) == label,
    );

    if (existingIndex >= 0) {
      current.removeAt(existingIndex);
    } else {
      current.add(item);
    }

    _selectedNotifier.value = current;
    widget.onChanged(current);
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? const Size(200, 48);

    return OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            // Full-screen transparent dismiss barrier
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeDropdown,
              ),
            ),
            // Floating Dropdown Menu Card
            Positioned(
              width: size.width,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(0, size.height + 4),
                child: Material(
                  elevation: 6,
                  shadowColor: Colors.black.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: ValueListenableBuilder<List<T>>(
                        valueListenable: _selectedNotifier,
                        builder: (ctx, selectedList, _) {
                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            shrinkWrap: true,
                            itemCount: widget.items.length,
                            itemBuilder: (ctx, index) {
                              final item = widget.items[index];
                              final isSelected = _isItemSelected(selectedList, item);
                              final label = widget.itemLabel(item);

                              return InkWell(
                                onTap: () => _toggleItem(item),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      // Checkmark icon slot (aligned with image)
                                      SizedBox(
                                        width: 22,
                                        child: isSelected
                                            ? const Icon(
                                                Icons.check,
                                                size: 18,
                                                color: Color(0xFF136B4F),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          label,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                            color: isSelected
                                                ? const Color(0xFF136B4F)
                                                : const Color(0xFF374151),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return ValueListenableBuilder<List<T>>(
      valueListenable: _selectedNotifier,
      builder: (context, selectedList, _) {
        final displayText = selectedList.map(widget.itemLabel).join(', ');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CompositedTransformTarget(
              link: _layerLink,
              child: InkWell(
                onTap: _toggleDropdown,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: hasError
                          ? AppColors.error
                          : (_isOpen
                              ? const Color(0xFF136B4F)
                              : const Color(0xFFD1D5DB)),
                      width: (_isOpen || hasError) ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: displayText.isEmpty
                            ? Text(
                                widget.isLoading
                                    ? 'Loading...'
                                    : (widget.hintText ?? 'Select'),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textLight,
                                ),
                              )
                            : Text(
                                displayText,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                      if (widget.isLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF136B4F),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 12),
                child: Text(
                  widget.errorText!,
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }
}

