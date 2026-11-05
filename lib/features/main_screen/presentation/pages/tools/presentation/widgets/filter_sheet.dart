import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:wm_mobile/core/theme/app_colors.dart';
import 'package:wm_mobile/core/theme/app_motion.dart';
import 'package:wm_mobile/core/widgets/app_text_field.dart';
import 'package:wm_mobile/core/widgets/gradient_button.dart';
import 'package:wm_mobile/core/widgets/press_scale.dart';
import 'package:wm_mobile/utils/formatters.dart';

import '../../data/tools_models.dart';

/// Opens the filter sheet for [type], starting from what is [current]ly applied.
/// Resolves to the new filters, or null if the sheet was dismissed.
Future<StockFilters?> showFilterSheet(
  BuildContext context, {
  required StockType type,
  required StockFilters current,
}) {
  return showModalBottomSheet<StockFilters>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => FilterSheet(type: type, current: current),
  );
}

/// The sheet's inputs are only a draft: "Qo'llash" applies them, and closing it
/// any other way discards them.
class FilterSheet extends StatefulWidget {
  const FilterSheet({super.key, required this.type, required this.current});

  final StockType type;
  final StockFilters current;

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late final FilterDraft _draft = FilterDraft.from(widget.current);

  late final _model = TextEditingController(text: _draft.model);
  late final _inventoryId = TextEditingController(text: _draft.inventoryId);
  late final _minPrice = TextEditingController(text: _draft.minPrice);
  late final _maxPrice = TextEditingController(text: _draft.maxPrice);
  late final _years = TextEditingController(text: _draft.years);

  String? _error;

  @override
  void dispose() {
    _model.dispose();
    _inventoryId.dispose();
    _minPrice.dispose();
    _maxPrice.dispose();
    _years.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  /// Clears the draft only. Nothing changes until "Qo'llash".
  void _clear() {
    setState(() {
      _draft
        ..createdAt = null
        ..status = null;
      _model.clear();
      _inventoryId.clear();
      _minPrice.clear();
      _maxPrice.clear();
      _years.clear();
      _error = null;
    });
  }

  void _apply() {
    _draft
      ..model = _model.text
      ..inventoryId = _inventoryId.text
      ..minPrice = _minPrice.text
      ..maxPrice = _maxPrice.text
      ..years = _years.text;

    final error = _draft.validate(widget.type);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(_draft.toFilters(widget.type));
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: parseIsoDate(_draft.createdAt) ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _draft.createdAt = isoDate(picked);
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.type;
    final media = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.88),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.blue, AppColors.abyss],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: AppColors.glassBorderStrong)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(type: type, onClear: _clear),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _Label("Qo'shilgan sana"),
                        _DateField(
                          value: _draft.createdAt,
                          onTap: _pickDate,
                          onClear: () => setState(() {
                            _draft.createdAt = null;
                          }),
                        ),
                        if (type.hasModelAndStatus) ...[
                          const _Label('Modeli'),
                          AppTextField(
                            controller: _model,
                            hint: 'Modelni kiriting',
                            icon: Icons.inventory_2_outlined,
                            textInputAction: TextInputAction.next,
                          ),
                          const _Label('Holati'),
                          _StatusPicker(
                            options: type.statuses,
                            selected: _draft.status,
                            onSelected: (status) =>
                                setState(() => _draft.status = status),
                          ),
                        ],
                        if (type.hasToolFilters) ...[
                          const _Label('Inventarizatsiya ID'),
                          AppTextField(
                            controller: _inventoryId,
                            hint: 'ID kiriting',
                            icon: Icons.qr_code_2_rounded,
                            textInputAction: TextInputAction.next,
                          ),
                          const _Label("Narxi (so'm)"),
                          Row(
                            children: [
                              Expanded(
                                child: _PriceField(
                                  controller: _minPrice,
                                  hint: 'dan',
                                  onChanged: _clearError,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Text(
                                  '—',
                                  style: TextStyle(
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: _PriceField(
                                  controller: _maxPrice,
                                  hint: 'gacha',
                                  onChanged: _clearError,
                                ),
                              ),
                            ],
                          ),
                          const _Label('Kirimdan beri (yil)'),
                          AppTextField(
                            controller: _years,
                            hint: 'Masalan: 4',
                            icon: Icons.event_available_rounded,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (_) => _clearError(),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 6, left: 4),
                            child: Text(
                              "To'liq o'tgan yillar soni",
                              style: TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: AppMotion.fast,
                  alignment: Alignment.topCenter,
                  child: _error == null
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: GradientButton(
                          label: 'Bekor qilish',
                          variant: ButtonVariant.glass,
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 10,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GradientButton(
                          label: "Qo'llash",
                          icon: Icons.check_rounded,
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 10,
                          ),
                          onPressed: _apply,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.type, required this.onClear});

  final StockType type;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          width: 42,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.glass(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 8, 2),
          child: Row(
            children: [
              const Icon(
                Icons.tune_rounded,
                color: AppColors.accentGlow,
                size: 21,
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'Filtrlar',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.glass(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          type.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                flex: 2,
                child: TextButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.undo_rounded, size: 17),
                  label: const Text(
                    'Tozalash',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8, left: 4),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PriceField extends StatelessWidget {
  const _PriceField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      hint: hint,
      icon: Icons.payments_outlined,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      onChanged: (_) => onChanged(),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  final String? value;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      scale: 0.98,
      child: Container(
        height: 56,
        padding: const EdgeInsets.only(left: 14, right: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.glass(0.12), AppColors.glass(0.06)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              color: AppColors.textSecondary,
              size: 19,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value == null ? 'Sanani tanlang' : formatDate(value),
                style: TextStyle(
                  fontSize: 15.5,
                  color: value == null
                      ? AppColors.textTertiary
                      : AppColors.textPrimary,
                ),
              ),
            ),
            if (value != null)
              IconButton(
                tooltip: 'Sanani tozalash',
                onPressed: onClear,
                icon: Icon(
                  Icons.close_rounded,
                  size: 19,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusPicker extends StatelessWidget {
  const _StatusPicker({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<ToolStatus> options;
  final ToolStatus? selected;
  final ValueChanged<ToolStatus?> onSelected;

  Widget _option(String label, ToolStatus? value) {
    final isSelected = selected == value;
    return PressScale(
      onTap: () => onSelected(value),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.30)
              : AppColors.glass(0.08),
          border: Border.all(
            color: isSelected
                ? AppColors.accentGlow.withValues(alpha: 0.85)
                : AppColors.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _option('Barchasi', null),
        for (final status in options) _option(status.label, status),
      ],
    );
  }
}
