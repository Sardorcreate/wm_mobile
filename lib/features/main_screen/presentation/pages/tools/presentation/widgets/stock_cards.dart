import 'package:flutter/material.dart';

import 'package:wm_mobile/core/theme/app_colors.dart';
import 'package:wm_mobile/core/theme/app_motion.dart';
import 'package:wm_mobile/core/widgets/glass_card.dart';
import 'package:wm_mobile/core/widgets/press_scale.dart';
import 'package:wm_mobile/utils/formatters.dart';

import '../../data/tools_models.dart';

/// The web page's table doesn't fit a phone, so each row becomes a card. The
/// cards skip blur: a page of `BackdropFilter`s costs more than it shows.

class ToolCard extends StatelessWidget {
  const ToolCard({
    super.key,
    required this.item,
    required this.number,
    required this.onOpen,
    required this.onDelete,
    this.isDeleting = false,
  });

  final ToolItem item;
  final int number;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      children: [
        _TitleRow(number: number, title: item.name ?? '-'),
        const SizedBox(height: 10),
        StatusLine(status: item.status),
        InfoLine(label: 'Modeli', value: item.model ?? '-'),
        InfoLine(label: 'Inventarizatsiya ID', value: item.inventoryId ?? '-'),
        InfoLine(label: "Qo'shilgan sanasi", value: formatDate(item.createdAt)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CardAction(
                label: 'Batafsil',
                icon: Icons.search_rounded,
                onTap: onOpen,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CardAction(
                label: "O'chirish",
                icon: Icons.delete_outline_rounded,
                destructive: true,
                isBusy: isDeleting,
                onTap: onDelete,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class SimpCard extends StatelessWidget {
  const SimpCard({super.key, required this.item, required this.number});

  final SimpItem item;
  final int number;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      children: [
        _TitleRow(number: number, title: capitalize(item.name)),
        const SizedBox(height: 10),
        StatusLine(status: item.status),
        InfoLine(label: 'Modeli', value: item.model ?? '-'),
        InfoLine(label: 'Soni', value: item.count?.toString() ?? '-'),
        InfoLine(label: 'Narxi', value: formatPrice(item.price)),
        InfoLine(label: "Qo'shilgan sanasi", value: formatDate(item.createdAt)),
        InfoLine(
          label: 'Yangilangan sanasi',
          value: formatDate(item.updatedAt),
        ),
      ],
    );
  }
}

class DocumentCard extends StatelessWidget {
  const DocumentCard({
    super.key,
    required this.item,
    required this.onDownload,
    this.onDelete,
    this.isDownloading = false,
    this.isDeleting = false,
  });

  final DocumentItem item;
  final VoidCallback onDownload;

  /// Null when this kind of document can't be deleted.
  final VoidCallback? onDelete;
  final bool isDownloading;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      children: [
        _TitleRow(number: item.id, title: formatDate(item.createdAt)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CardAction(
                label: 'Yuklab olish',
                icon: Icons.download_rounded,
                isBusy: isDownloading,
                onTap: onDownload,
              ),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 8),
              Expanded(
                child: CardAction(
                  label: "O'chirish",
                  icon: Icons.delete_outline_rounded,
                  destructive: true,
                  isBusy: isDeleting,
                  onTap: onDelete!,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      blur: 0,
      radius: 20,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.number, required this.title});

  final int number;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: const BoxConstraints(minWidth: 30),
          height: 30,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: AppColors.glass(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$number',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The "Holati" row: the label on the left, the status on the right.
class StatusLine extends StatelessWidget {
  const StatusLine({super.key, required this.status});

  final ToolStatus? status;

  @override
  Widget build(BuildContext context) {
    final current = status;
    if (current == null) return const InfoLine(label: 'Holati', value: '-');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Holati',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: StatusPill(status: current),
            ),
          ),
        ],
      ),
    );
  }
}

/// A label on the left, its value on the right. Either side wraps rather than
/// overflowing on a narrow screen or with large system text.
class InfoLine extends StatelessWidget {
  const InfoLine({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});

  final ToolStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color color, IconData icon) = switch (status) {
      ToolStatus.inactive => (AppColors.danger, Icons.block_rounded),
      ToolStatus.reserve => (AppColors.accentGlow, Icons.inventory_2_rounded),
      ToolStatus.inUsage => (AppColors.success, Icons.person_rounded),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              status.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CardAction extends StatelessWidget {
  const CardAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.destructive = false,
    this.isBusy = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.danger : AppColors.textPrimary;

    return PressScale(
      onTap: isBusy ? null : onTap,
      child: Container(
        height: 42,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          color: destructive
              ? AppColors.danger.withValues(alpha: 0.10)
              : AppColors.glass(0.12),
          border: Border.all(
            color: destructive
                ? AppColors.danger.withValues(alpha: 0.5)
                : AppColors.glassBorder,
          ),
        ),
        child: AnimatedSwitcher(
          duration: AppMotion.fast,
          child: isBusy
              ? SizedBox(
                  key: const ValueKey('busy'),
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              : Row(
                  key: const ValueKey('idle'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 17, color: color),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
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

/// Placeholder rows while a page loads. Keeps the list's shape instead of
/// collapsing it to a lone spinner.
class StockSkeleton extends StatefulWidget {
  const StockSkeleton({super.key, this.count = 4});

  final int count;

  @override
  State<StockSkeleton> createState() => _StockSkeletonState();
}

class _StockSkeletonState extends State<StockSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Widget _bar(double widthFactor, double height) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.glass(0.16),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(_pulse),
      child: Column(
        children: [
          for (var i = 0; i < widget.count; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                blur: 0,
                radius: 20,
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _bar(0.6, 16),
                    const SizedBox(height: 12),
                    _bar(0.9, 11),
                    const SizedBox(height: 8),
                    _bar(0.75, 11),
                    const SizedBox(height: 8),
                    _bar(0.5, 11),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
