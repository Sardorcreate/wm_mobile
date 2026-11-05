import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:wm_mobile/core/feedback/app_snack_bar.dart';
import 'package:wm_mobile/core/feedback/confirm_dialog.dart';
import 'package:wm_mobile/core/files/file_export.dart';
import 'package:wm_mobile/core/navigation/app_routes.dart';
import 'package:wm_mobile/core/network/api_client.dart';
import 'package:wm_mobile/core/theme/app_colors.dart';
import 'package:wm_mobile/core/theme/app_motion.dart';
import 'package:wm_mobile/core/widgets/entrance.dart';
import 'package:wm_mobile/core/widgets/gradient_button.dart';
import 'package:wm_mobile/core/widgets/press_scale.dart';
import 'package:wm_mobile/features/auth/controller/auth_service.dart';

import '../../data/tools_api.dart';
import '../../data/tools_models.dart';
import '../../data/tools_search_controller.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/search_panel.dart';
import '../widgets/stock_cards.dart';
import 'tool_details_screen.dart';

/// The "Jihozlar" tab: native version of the web client's exist page.
class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key, this.api});

  /// Defaults to the app's authenticated API. Tests pass their own.
  final ToolsApi? api;

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  late final ToolsSearchController _search = ToolsSearchController(
    widget.api ?? ToolsApi(AuthService.instance.api),
  );

  final Set<int> _deleting = {};
  final Set<int> _downloading = {};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openFilters() async {
    final type = _search.type;
    if (type == null) return;

    final filters = await showFilterSheet(
      context,
      type: type,
      current: _search.filters,
    );
    if (filters != null && mounted) await _search.applyFilters(filters);
  }

  Future<void> _openTool(int id) async {
    await Navigator.of(context).push<void>(
      appRoute<void>(
        ToolDetailsScreen(id: id, api: _search.api),
        transition: AppTransition.sharedAxis,
      ),
    );
    // The tool may have been edited, handed back or deleted in there.
    if (mounted) await _search.reload();
  }

  Future<void> _delete(StockType type, int id) async {
    final confirmed = await showConfirmDialog(
      context,
      title: "O'chirishni tasdiqlang",
      message: "Siz buni rostdan ham o'chirmoqchimisiz?",
      confirmLabel: "O'chirish",
      icon: Icons.delete_outline_rounded,
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _deleting.add(id));
    try {
      final message = await _search.api.delete(type, id);
      if (!mounted) return;
      AppSnackBar.success(
        context,
        message.isEmpty ? "Muvaffaqqiyatli o'chirildi!" : message,
      );
      await _search.reload();
    } on SessionExpiredException {
      // AuthGuard is already taking the user to the login page.
    } on ApiException catch (e) {
      if (mounted) AppSnackBar.error(context, e.message);
    } finally {
      if (mounted) setState(() => _deleting.remove(id));
    }
  }

  Future<void> _download(StockType type, int id) async {
    setState(() => _downloading.add(id));
    try {
      final file = await _search.api.downloadDocument(type, id);
      if (!mounted) return;
      await FileExport.share(context, file);
    } on SessionExpiredException {
      // AuthGuard is already taking the user to the login page.
    } on ApiException catch (e) {
      if (mounted) AppSnackBar.error(context, e.message);
    } on Exception {
      if (mounted) AppSnackBar.error(context, "Faylni ochib bo'lmadi");
    } finally {
      if (mounted) setState(() => _downloading.remove(id));
    }
  }

  Widget _card(StockType type, StockItem item, int number) {
    return switch (item) {
      ToolItem() => ToolCard(
        item: item,
        number: number,
        isDeleting: _deleting.contains(item.id),
        onOpen: () => _openTool(item.id),
        onDelete: () => _delete(type, item.id),
      ),
      SimpItem() => SimpCard(item: item, number: number),
      DocumentItem() => DocumentCard(
        item: item,
        isDownloading: _downloading.contains(item.id),
        isDeleting: _deleting.contains(item.id),
        onDownload: () => _download(type, item.id),
        onDelete: type.canDelete ? () => _delete(type, item.id) : null,
      ),
    };
  }

  Widget _results() {
    final type = _search.type;

    if (type == null) {
      return const _Message(
        icon: Icons.touch_app_rounded,
        text: 'Iltimos, avval qurilma turini tanlang.',
      );
    }

    return switch (_search.phase) {
      SearchPhase.idle => const SizedBox.shrink(),
      SearchPhase.loading => const StockSkeleton(),
      SearchPhase.empty => const _Message(
        icon: Icons.search_off_rounded,
        text: 'Hech narsa topilmadi',
      ),
      SearchPhase.error => _Message(
        icon: Icons.cloud_off_rounded,
        text: _search.error ?? "Server bilan bog'lanishda xatolik.",
        onRetry: _search.reload,
      ),
      SearchPhase.ready => Column(
        children: [
          for (final (index, item) in _search.result.items.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Entrance(
                key: ValueKey('${_search.generation}-$index'),
                delay: Duration(milliseconds: 35 * index),
                child: _card(type, item, _search.firstShown + index),
              ),
            ),
          _Pagination(search: _search),
        ],
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    // The floating nav bar overlaps the body, which reports its height as
    // bottom padding. The floor covers anywhere the padding isn't forwarded.
    final bottom = math.max(MediaQuery.paddingOf(context).bottom, 96.0) + 16;

    return ListenableBuilder(
      listenable: _search,
      builder: (context, _) {
        return RefreshIndicator(
          color: AppColors.indigo,
          backgroundColor: Colors.white,
          onRefresh: () async {
            if (_search.type != null) await _search.reload();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
            children: [
              SearchPanel(controller: _search, onOpenFilters: _openFilters),
              const SizedBox(height: 18),
              _ResultsHeader(
                total: _search.phase == SearchPhase.ready
                    ? _search.result.totalItems
                    : 0,
              ),
              const SizedBox(height: 10),
              AnimatedSwitcher(
                duration: AppMotion.medium,
                switchInCurve: AppMotion.standard,
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topCenter,
                  children: [...previous, ?current],
                ),
                child: KeyedSubtree(
                  key: ValueKey(
                    '${_search.type?.path}-${_search.phase.name}-'
                    '${_search.generation}',
                  ),
                  child: _results(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 4),
        const Text(
          'Natijalar',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 10),
        AnimatedSwitcher(
          duration: AppMotion.fast,
          child: Container(
            key: ValueKey(total),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.glass(0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$total',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.onRetry});

  final IconData icon;
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      child: Column(
        children: [
          Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.glass(0.08),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Icon(icon, size: 32, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14.5,
              height: 1.35,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              child: GradientButton(
                label: 'Qayta urinish',
                icon: Icons.refresh_rounded,
                variant: ButtonVariant.glass,
                padding: const EdgeInsets.symmetric(
                  vertical: 13,
                  horizontal: 10,
                ),
                onPressed: onRetry,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Pagination extends StatelessWidget {
  const _Pagination({required this.search});

  final ToolsSearchController search;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                '${search.firstShown}–${search.lastShown} / '
                '${search.result.totalItems} ta',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          _PageButton(
            icon: Icons.chevron_left_rounded,
            tooltip: 'Oldingi sahifa',
            onTap: search.hasPrevious
                ? () => search.search(page: search.page - 1)
                : null,
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            constraints: const BoxConstraints(minWidth: 34),
            height: 34,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              gradient: LinearGradient(
                colors: [
                  AppColors.accent.withValues(alpha: 0.42),
                  AppColors.accent.withValues(alpha: 0.18),
                ],
              ),
            ),
            child: Text(
              '${search.page}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _PageButton(
            icon: Icons.chevron_right_rounded,
            tooltip: 'Keyingi sahifa',
            onTap: search.hasNext
                ? () => search.search(page: search.page + 1)
                : null,
          ),
        ],
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: PressScale(
        onTap: onTap,
        scale: 0.9,
        child: AnimatedOpacity(
          duration: AppMotion.fast,
          opacity: enabled ? 1 : 0.35,
          child: Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: AppColors.glass(0.12),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Icon(icon, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}
