import 'package:flutter/material.dart';

import 'package:wm_mobile/core/theme/app_colors.dart';
import 'package:wm_mobile/core/theme/app_motion.dart';
import 'package:wm_mobile/core/widgets/app_text_field.dart';
import 'package:wm_mobile/core/widgets/glass_card.dart';
import 'package:wm_mobile/core/widgets/gradient_button.dart';
import 'package:wm_mobile/core/widgets/press_scale.dart';

import '../../data/tools_models.dart';
import '../../data/tools_search_controller.dart';

const _compactButton = EdgeInsets.symmetric(vertical: 15, horizontal: 12);

/// The top of the tab: what to search for, the name box and the applied filters.
/// Everything else lives in the filter sheet.
class SearchPanel extends StatelessWidget {
  const SearchPanel({
    super.key,
    required this.controller,
    required this.onOpenFilters,
  });

  final ToolsSearchController controller;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final type = controller.type;
    final applied = controller.filters.applied;

    return GlassCard(
      blur: 0,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Nima qidiryapsiz?',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          _TypeGrid(selected: type, onSelected: controller.selectType),
          AnimatedSize(
            duration: AppMotion.medium,
            curve: AppMotion.emphasized,
            alignment: Alignment.topCenter,
            child: type?.hasName ?? false
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: AppTextField(
                      controller: controller.nameController,
                      hint: 'Jihoz nomini kiriting',
                      icon: Icons.sell_outlined,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => controller.search(),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GradientButton(
                      label: 'Filtrlar',
                      icon: Icons.tune_rounded,
                      variant: ButtonVariant.glass,
                      padding: _compactButton,
                      onPressed: type == null ? null : onOpenFilters,
                    ),
                    if (applied.isNotEmpty)
                      Positioned(
                        top: -6,
                        right: -2,
                        child: _CountBadge(count: applied.length),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GradientButton(
                  label: 'Qidirish',
                  icon: Icons.search_rounded,
                  padding: _compactButton,
                  onPressed: type == null ? null : controller.search,
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: AppMotion.medium,
            curve: AppMotion.emphasized,
            alignment: Alignment.topCenter,
            child: applied.isEmpty
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _AppliedChips(
                      applied: applied,
                      onRemove: controller.removeFilter,
                      onClear: controller.clearFilters,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TypeGrid extends StatelessWidget {
  const _TypeGrid({required this.selected, required this.onSelected});

  final StockType? selected;
  final ValueChanged<StockType> onSelected;

  static IconData _icon(StockType type) => switch (type) {
    StockType.order => Icons.move_to_inbox_rounded,
    StockType.tool => Icons.memory_rounded,
    StockType.simp => Icons.mouse_rounded,
    StockType.outcome => Icons.outbox_rounded,
  };

  Widget _tile(StockType type) => Expanded(
    child: _TypeTile(
      label: type.label,
      icon: _icon(type),
      selected: type == selected,
      onTap: () => onSelected(type),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _tile(StockType.order),
            const SizedBox(width: 8),
            _tile(StockType.tool),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _tile(StockType.simp),
            const SizedBox(width: 8),
            _tile(StockType.outcome),
          ],
        ),
      ],
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: PressScale(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.medium,
          curve: AppMotion.standard,
          constraints: const BoxConstraints(minHeight: 54),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: selected
                  ? [
                      AppColors.accent.withValues(alpha: 0.42),
                      AppColors.accent.withValues(alpha: 0.16),
                    ]
                  : [AppColors.glass(0.10), AppColors.glass(0.04)],
            ),
            border: Border.all(
              color: selected
                  ? AppColors.accentGlow.withValues(alpha: 0.85)
                  : AppColors.glassBorder,
              width: selected ? 1.4 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.25),
                      blurRadius: 16,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected
                    ? AppColors.accentGlow
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.15,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      height: 22,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          colors: [AppColors.accentGlow, AppColors.accent],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.5),
            blurRadius: 8,
          ),
        ],
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: AppColors.indigo,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// What is applied right now. Filters hidden in a sheet must never be invisible
/// filters.
class _AppliedChips extends StatelessWidget {
  const _AppliedChips({
    required this.applied,
    required this.onRemove,
    required this.onClear,
  });

  final List<AppliedFilter> applied;
  final ValueChanged<FilterKey> onRemove;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final filter in applied)
          _Chip(filter: filter, onRemove: () => onRemove(filter.key)),
        PressScale(
          onTap: onClear,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Text(
              'Barchasini tozalash',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.filter, required this.onRemove});

  final AppliedFilter filter;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AppColors.glass(0.12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${filter.label}: ',
                    style: TextStyle(color: AppColors.textTertiary),
                  ),
                  TextSpan(text: filter.text),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            height: 34,
            width: 34,
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 16,
              tooltip: "${filter.label} filtrini olib tashlash",
              onPressed: onRemove,
              icon: Icon(Icons.close_rounded, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
