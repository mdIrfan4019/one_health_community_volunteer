// Reusable Inline Searchable Dropdown Component (matches Volunteer Registration screen)
// File: lib/core/widgets/searchable_dropdown.dart

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// FormField wrapper for inline searchable dropdown matching Volunteer Registration
class SearchableDropdownFormField<T> extends FormField<T> {
  final String fieldId;
  final List<T> items;
  final String Function(T) itemLabel;
  final String Function(T)? itemSubtitle;
  final bool Function(T item, String query)? searchMatcher;
  final ValueChanged<T?>? onChanged;
  final String? hintText;
  final bool isLoading;
  final VoidCallback? onRetry;

  SearchableDropdownFormField({
    super.key,
    required this.fieldId,
    required this.items,
    required this.itemLabel,
    this.itemSubtitle,
    this.searchMatcher,
    this.onChanged,
    T? value,
    super.validator,
    this.hintText,
    this.isLoading = false,
    this.onRetry,
    // Optional compatibility parameters
    String? title,
    String? searchHint,
  }) : super(
          initialValue: (value != null && items.contains(value)) ? value : null,
          builder: (FormFieldState<T> state) {
            final validValue =
                (state.value != null && items.contains(state.value))
                    ? state.value
                    : null;

            return _InlineSearchableDropdown<T>(
              fieldId: fieldId,
              value: validValue,
              items: items,
              itemLabel: itemLabel,
              itemSubtitle: itemSubtitle,
              searchMatcher: searchMatcher,
              onChanged: (selected) {
                state.didChange(selected);
                onChanged?.call(selected);
              },
              isLoading: isLoading,
              hintText: hintText,
              onRetry: onRetry,
              errorText: state.errorText,
            );
          },
        );

  @override
  FormFieldState<T> createState() => _SearchableDropdownFormFieldState<T>();
}

class _SearchableDropdownFormFieldState<T> extends FormFieldState<T> {
  @override
  void didUpdateWidget(SearchableDropdownFormField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      setValue(widget.initialValue);
    }
  }

  @override
  void reset() {
    super.reset();
    (widget as SearchableDropdownFormField<T>).onChanged?.call(value);
  }
}

class _InlineSearchableDropdown<T> extends StatefulWidget {
  final String fieldId;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final String Function(T)? itemSubtitle;
  final bool Function(T item, String query)? searchMatcher;
  final ValueChanged<T?> onChanged;
  final bool isLoading;
  final String? hintText;
  final VoidCallback? onRetry;
  final String? errorText;

  const _InlineSearchableDropdown({
    super.key,
    required this.fieldId,
    required this.value,
    required this.items,
    required this.itemLabel,
    this.itemSubtitle,
    this.searchMatcher,
    required this.onChanged,
    this.isLoading = false,
    this.hintText,
    this.onRetry,
    this.errorText,
  });

  @override
  State<_InlineSearchableDropdown<T>> createState() =>
      _InlineSearchableDropdownState<T>();
}

class _InlineSearchableDropdownState<T>
    extends State<_InlineSearchableDropdown<T>> {
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();
  late TextEditingController _controller;
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  List<T> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value != null ? widget.itemLabel(widget.value as T) : '',
    );
    _filteredItems = List.from(widget.items);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant _InlineSearchableDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      _filteredItems = List.from(widget.items);
    }
    if (widget.value != oldWidget.value) {
      if (!_focusNode.hasFocus) {
        _controller.text =
            widget.value != null ? widget.itemLabel(widget.value as T) : '';
      }
    }
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isOpen = false;
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
      // Show all items on initial open so user can browse or type to filter
      setState(() {
        _filteredItems = List.from(widget.items);
      });
      _overlayEntry?.markNeedsBuild();
      _showOverlay();
    } else {
      _removeOverlay();
      final text = _controller.text.trim();
      try {
        final exactMatch = widget.items.firstWhere(
          (i) => widget.itemLabel(i).toLowerCase() == text.toLowerCase(),
        );
        _controller.text = widget.itemLabel(exactMatch);
        if (exactMatch != widget.value) {
          widget.onChanged(exactMatch);
        }
      } catch (_) {
        _controller.text =
            widget.value != null ? widget.itemLabel(widget.value as T) : '';
      }
    }
  }

  void _filterItems(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredItems = List.from(widget.items);
      } else {
        _filteredItems = widget.items.where((item) {
          if (widget.searchMatcher != null) {
            return widget.searchMatcher!(item, q);
          }
          final label = widget.itemLabel(item).toLowerCase();
          final subtitle =
              widget.itemSubtitle?.call(item).toLowerCase() ?? '';
          return label.contains(q) || subtitle.contains(q);
        }).toList();
      }
    });
    _overlayEntry?.markNeedsBuild();
  }

  void _showOverlay() {
    if (_isOpen || !mounted || widget.isLoading) return;
    if (widget.items.isEmpty) return;
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _removeOverlay() {
    if (!_isOpen) return;
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() => _isOpen = false);
    }
  }

  void _selectItem(T item) {
    _controller.text = widget.itemLabel(item);
    widget.onChanged(item);
    _focusNode.unfocus();
    _removeOverlay();
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (overlayContext) {
        return Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, size.height + 4),
            child: TapRegion(
              groupId: widget.fieldId,
              child: Material(
                elevation: 6,
                shadowColor: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _filteredItems.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(14.0),
                            child: Text(
                              'No matching options',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            shrinkWrap: true,
                            itemCount: _filteredItems.length,
                            separatorBuilder: (context, index) => const Divider(
                              height: 1,
                              color: Color(0xFFF1F5F9),
                            ),
                            itemBuilder: (context, index) {
                              final item = _filteredItems[index];
                              final label = widget.itemLabel(item);
                              final subtitle = widget.itemSubtitle?.call(item);
                              final isSelected = item == widget.value ||
                                  label.toLowerCase() ==
                                      _controller.text.trim().toLowerCase();

                              return InkWell(
                                onTap: () => _selectItem(item),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  color: isSelected
                                      ? AppColors.primary
                                          .withValues(alpha: 0.08)
                                      : Colors.transparent,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              label,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                                color: isSelected
                                                    ? AppColors.primary
                                                    : AppColors.textDark,
                                              ),
                                            ),
                                            if (subtitle != null &&
                                                subtitle.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                subtitle,
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  color: AppColors.textMuted,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_rounded,
                                          size: 18,
                                          color: AppColors.primary,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return TapRegion(
      groupId: widget.fieldId,
      onTapOutside: (_) {
        if (_focusNode.hasFocus) {
          _focusNode.unfocus();
        }
      },
      child: CompositedTransformTarget(
        link: _layerLink,
        child: TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          readOnly: widget.isLoading ||
              (widget.items.isEmpty && widget.onRetry != null),
          style: const TextStyle(fontSize: 14, color: AppColors.textDark),
          onTap: () {
            if (!_isOpen && widget.items.isNotEmpty) {
              _showOverlay();
            }
          },
          onChanged: (val) {
            _filterItems(val);
            if (!_isOpen) {
              _showOverlay();
            }
          },
          decoration: InputDecoration(
            hintText: widget.isLoading
                ? (widget.hintText ?? 'Loading...')
                : (widget.hintText ?? 'Select'),
            hintStyle: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textLight,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            errorText: widget.errorText,
            suffixIcon: widget.isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : (widget.items.isEmpty && widget.onRetry != null)
                    ? InkWell(
                        onTap: widget.onRetry,
                        child: const Icon(
                          Icons.refresh,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      )
                    : IconButton(
                        icon: Icon(
                          _isOpen
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: AppColors.primary,
                        ),
                        onPressed: () {
                          if (_focusNode.hasFocus) {
                            _focusNode.unfocus();
                          } else {
                            _focusNode.requestFocus();
                          }
                        },
                      ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError
                    ? AppColors.error
                    : (_isOpen ? AppColors.primary : AppColors.border),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? AppColors.error : AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
