// Multi-Select Searchable Dropdown Component
// File: lib/core/widgets/multi_select_dropdown.dart

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// FormField wrapper for multi-select dropdown with modal search & checkboxes
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

class _MultiSelectDropdownWidget<T> extends StatelessWidget {
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

  void _showBottomSheet(BuildContext context) {
    if (isLoading || items.isEmpty) return;

    final tempSelected = List<T>.from(selectedValues);

    showModalBottomSheet<List<T>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        final mediaQuery = MediaQuery.of(bottomSheetContext);
        return _MultiSelectBottomSheetContent<T>(
          title: title,
          items: items,
          itemLabel: itemLabel,
          searchMatcher: searchMatcher,
          initialSelected: tempSelected,
          mediaQuery: mediaQuery,
        );
      },
    ).then((result) {
      if (result != null) {
        onChanged(result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

    // Summary display text inside the closed field
    String displayText = '';
    if (selectedValues.isEmpty) {
      displayText = '';
    } else if (selectedValues.length == 1) {
      displayText = itemLabel(selectedValues.first);
    } else {
      displayText =
          '${selectedValues.length} selected: ${selectedValues.map(itemLabel).join(', ')}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main Clickable Dropdown Tile
        InkWell(
          onTap: () => _showBottomSheet(context),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasError ? AppColors.error : AppColors.border,
                width: hasError ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: displayText.isEmpty
                      ? Text(
                          isLoading ? 'Loading...' : (hintText ?? 'Select'),
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: AppColors.textLight,
                          ),
                        )
                      : Text(
                          displayText,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: AppColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                else
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.primary,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),

        // Error message if validation failed
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              errorText!,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),

        // Selected Items Chips
        if (selectedValues.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: selectedValues.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        itemLabel(item),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () {
                        final updated = List<T>.from(selectedValues)
                          ..remove(item);
                        onChanged(updated);
                      },
                      child: const Icon(
                        Icons.close_rounded,
                        size: 15,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _MultiSelectBottomSheetContent<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T) itemLabel;
  final bool Function(T item, String query)? searchMatcher;
  final List<T> initialSelected;
  final MediaQueryData mediaQuery;

  const _MultiSelectBottomSheetContent({
    required this.title,
    required this.items,
    required this.itemLabel,
    this.searchMatcher,
    required this.initialSelected,
    required this.mediaQuery,
  });

  @override
  State<_MultiSelectBottomSheetContent<T>> createState() =>
      _MultiSelectBottomSheetContentState<T>();
}

class _MultiSelectBottomSheetContentState<T>
    extends State<_MultiSelectBottomSheetContent<T>> {
  late List<T> _selected;
  final TextEditingController _searchController = TextEditingController();
  List<T> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _selected = List<T>.from(widget.initialSelected);
    _filteredItems = List<T>.from(widget.items);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filter(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredItems = List<T>.from(widget.items);
      } else {
        _filteredItems = widget.items.where((item) {
          if (widget.searchMatcher != null) {
            return widget.searchMatcher!(item, q);
          }
          return widget.itemLabel(item).toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  void _toggle(T item) {
    setState(() {
      if (_selected.contains(item)) {
        _selected.remove(item);
      } else {
        _selected.add(item);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = widget.mediaQuery.size.height * 0.80;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: widget.mediaQuery.viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      if (_selected.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_selected.length}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: _filter,
                style: const TextStyle(fontSize: 13.5, color: AppColors.textDark),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            _filter('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            // Quick select / clear bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_filteredItems.length} available',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  if (_selected.isNotEmpty)
                    InkWell(
                      onTap: () => setState(() => _selected.clear()),
                      child: const Text(
                        'Clear all',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 12, color: AppColors.divider),

            // Checkbox List
            Flexible(
              child: _filteredItems.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text(
                          'No topics match your search.',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        final isSelected = _selected.contains(item);

                        return InkWell(
                          onTap: () => _toggle(item),
                          child: Container(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.05)
                                : Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: Checkbox(
                                    value: isSelected,
                                    activeColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    onChanged: (_) => _toggle(item),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    widget.itemLabel(item),
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            const Divider(height: 1, color: AppColors.divider),

            // Bottom Done Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    _selected.isEmpty
                        ? 'Done'
                        : 'Done (${_selected.length} selected)',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
