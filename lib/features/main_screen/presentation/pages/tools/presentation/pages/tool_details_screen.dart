import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:wm_mobile/core/feedback/app_snack_bar.dart';
import 'package:wm_mobile/core/feedback/confirm_dialog.dart';
import 'package:wm_mobile/core/files/file_export.dart';
import 'package:wm_mobile/core/network/api_client.dart';
import 'package:wm_mobile/core/theme/app_colors.dart';
import 'package:wm_mobile/core/theme/app_motion.dart';
import 'package:wm_mobile/core/widgets/app_text_field.dart';
import 'package:wm_mobile/core/widgets/entrance.dart';
import 'package:wm_mobile/core/widgets/glass_card.dart';
import 'package:wm_mobile/core/widgets/gradient_button.dart';
import 'package:wm_mobile/utils/formatters.dart';

import '../../data/tools_api.dart';
import '../../data/tools_models.dart';
import '../widgets/stock_cards.dart';

/// Native version of the web client's details page. What can be done to a tool
/// depends on its status:
///
/// * inactive: fill in the inventory ID and description, which activates it;
/// * in the warehouse: handing it over happens on the outcome page;
/// * in use: print its codes, take it back, or edit its description.
class ToolDetailsScreen extends StatefulWidget {
  const ToolDetailsScreen({super.key, required this.id, required this.api});

  final int id;
  final ToolsApi api;

  @override
  State<ToolDetailsScreen> createState() => _ToolDetailsScreenState();
}

enum _Action { activate, qr, takeAway, saveDescription, delete }

class _ToolDetailsScreenState extends State<ToolDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _inventoryId = TextEditingController();
  final _description = TextEditingController();

  ToolDetails? _tool;
  String? _loadError;
  _Action? _busy;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _inventoryId.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);

    try {
      final tool = await widget.api.getTool(widget.id);
      if (!mounted) return;
      _inventoryId.text = tool.inventoryId ?? '';
      _description.text = tool.description ?? '';
      setState(() => _tool = tool);
    } on SessionExpiredException {
      // AuthGuard is already taking the user to the login page.
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e.message);
    }
  }

  /// Runs [action], reports the outcome and reloads the tool.
  Future<void> _run(_Action action, Future<String> Function() run) async {
    setState(() => _busy = action);
    try {
      final message = await run();
      if (!mounted) return;
      AppSnackBar.success(
        context,
        message.isEmpty ? "Muvaffaqqiyatli o'zgartirildi!" : message,
      );
      await _load();
    } on SessionExpiredException {
      // AuthGuard is already taking the user to the login page.
    } on ApiException catch (e) {
      if (mounted) AppSnackBar.error(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _activate() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await _run(
      _Action.activate,
      () => widget.api.activateTool(
        widget.id,
        inventoryId: _inventoryId.text.trim(),
        description: _description.text.trim(),
      ),
    );
  }

  Future<void> _saveDescription() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Saqlashni tasdiqlang',
      message: "Ushbu ma'lumotlarni saqlamoqchimisiz?",
      confirmLabel: 'Saqlash',
      icon: Icons.save_outlined,
    );
    if (!confirmed || !mounted) return;
    await _run(
      _Action.saveDescription,
      () => widget.api.updateDescription(widget.id, _description.text.trim()),
    );
  }

  Future<void> _takeAway() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Olib qo\'yishni tasdiqlang',
      message: "Rostdan ham ushbu qurilmani olib qo'ymoqchimisiz?",
      confirmLabel: "Olib qo'yish",
      icon: Icons.assignment_return_outlined,
    );
    if (!confirmed || !mounted) return;
    await _run(_Action.takeAway, () => widget.api.takeAway(widget.id));
  }

  Future<void> _downloadCodes() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'QR va Shtrix kod',
      message: 'Rostdan ham QR va Shtrix kodlarni olmoqchimisiz?',
      confirmLabel: 'Yuklab olish',
      icon: Icons.qr_code_2_rounded,
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = _Action.qr);
    try {
      final file = await widget.api.qrSheet(widget.id);
      if (!mounted) return;
      await FileExport.share(context, file);
    } on SessionExpiredException {
      // AuthGuard is already taking the user to the login page.
    } on ApiException catch (e) {
      if (mounted) AppSnackBar.error(context, e.message);
    } on Exception {
      if (mounted) AppSnackBar.error(context, "Faylni ochib bo'lmadi");
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showConfirmDialog(
      context,
      title: "O'chirishni tasdiqlang",
      message: "Siz haqiqatdan ham buni o'chirmoqchimisiz?",
      confirmLabel: "O'chirish",
      icon: Icons.delete_outline_rounded,
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = _Action.delete);
    try {
      final message = await widget.api.delete(StockType.tool, widget.id);
      if (!mounted) return;
      AppSnackBar.success(
        context,
        message.isEmpty ? "Muvaffaqqiyatli o'chirildi!" : message,
      );
      Navigator.of(context).pop();
    } on SessionExpiredException {
      // AuthGuard is already taking the user to the login page.
    } on ApiException catch (e) {
      if (mounted) AppSnackBar.error(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Batafsil ma'lumotlar")),
      body: AnimatedSwitcher(
        duration: AppMotion.medium,
        child: KeyedSubtree(
          key: ValueKey(_tool != null ? 'tool' : (_loadError ?? 'loading')),
          child: _body(),
        ),
      ),
    );
  }

  Widget _body() {
    final tool = _tool;
    if (tool != null) return _details(tool);

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 40,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 14),
              Text(
                _loadError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 200,
                child: GradientButton(
                  label: 'Qayta urinish',
                  icon: Icons.refresh_rounded,
                  variant: ButtonVariant.glass,
                  onPressed: _load,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
  }

  Widget _details(ToolDetails tool) {
    return SafeArea(
      top: false,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        children: [
          Entrance(child: _InfoCard(tool: tool)),
          const SizedBox(height: 14),
          Entrance(
            delay: AppMotion.stagger,
            child: AnimatedSize(
              duration: AppMotion.medium,
              curve: AppMotion.emphasized,
              alignment: Alignment.topCenter,
              child: _actionsFor(tool),
            ),
          ),
          const SizedBox(height: 14),
          Entrance(
            delay: AppMotion.stagger * 2,
            child: GradientButton(
              label: "O'chirish",
              icon: Icons.delete_outline_rounded,
              variant: ButtonVariant.danger,
              isLoading: _busy == _Action.delete,
              onPressed: _busy == null ? _delete : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionsFor(ToolDetails tool) {
    return switch (tool.status) {
      ToolStatus.inactive => _activateForm(),
      ToolStatus.reserve => const _InWarehouseNotice(),
      ToolStatus.inUsage => _inUseActions(tool),
      null => const SizedBox(width: double.infinity),
    };
  }

  Widget _activateForm() {
    return GlassCard(
      blur: 0,
      padding: const EdgeInsets.all(14),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionTitle("Ma'lumotlarni tahrirlash"),
            const SizedBox(height: 12),
            AppTextField(
              controller: _inventoryId,
              hint: 'Inventarizatsiya raqamini kiriting',
              icon: Icons.qr_code_2_rounded,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.next,
              validator: _required,
            ),
            const SizedBox(height: 10),
            AppTextField(
              controller: _description,
              hint: "Qo'shimcha ma'lumotlar",
              icon: Icons.notes_rounded,
              validator: _required,
            ),
            const SizedBox(height: 12),
            GradientButton(
              label: 'Saqlash',
              icon: Icons.check_rounded,
              isLoading: _busy == _Action.activate,
              onPressed: _busy == null ? _activate : null,
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) =>
      (value?.trim().isEmpty ?? true) ? "To'ldirilishi shart" : null;

  Widget _inUseActions(ToolDetails tool) {
    return GlassCard(
      blur: 0,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle('QR va Shtrix kodni yuklab olish'),
          const SizedBox(height: 10),
          GradientButton(
            label: 'Yuklab olish',
            icon: Icons.download_rounded,
            variant: ButtonVariant.glass,
            isLoading: _busy == _Action.qr,
            onPressed: _busy == null ? _downloadCodes : null,
          ),
          const SizedBox(height: 18),
          _SectionTitle("Qurilmani ${tool.owner ?? 'xodim'}dan olib qo'yish"),
          const SizedBox(height: 10),
          GradientButton(
            label: 'Tasdiqlash',
            icon: Icons.assignment_return_outlined,
            variant: ButtonVariant.glass,
            isLoading: _busy == _Action.takeAway,
            onPressed: _busy == null ? _takeAway : null,
          ),
          const SizedBox(height: 18),
          const _SectionTitle("Ma'lumotni o'zgartirish"),
          const SizedBox(height: 10),
          AppTextField(
            controller: _description,
            hint: "Qo'shimcha ma'lumotlar",
            icon: Icons.notes_rounded,
          ),
          const SizedBox(height: 10),
          GradientButton(
            label: 'Saqlash',
            icon: Icons.save_outlined,
            isLoading: _busy == _Action.saveDescription,
            onPressed: _busy == null ? _saveDescription : null,
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.tool});

  final ToolDetails tool;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      blur: 0,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tool.name ?? '-',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          StatusLine(status: tool.status),
          InfoLine(label: 'Egasi', value: tool.owner ?? '-'),
          InfoLine(label: 'Modeli', value: tool.model ?? '-'),
          InfoLine(
            label: 'Inventarizatsiya ID',
            value: tool.inventoryId ?? '-',
          ),
          InfoLine(label: 'Yaratilgan', value: formatDate(tool.createdAt)),
          InfoLine(label: 'Yangilangan', value: formatDate(tool.updatedAt)),
          InfoLine(label: 'Qayerdan keltirilgan', value: tool.whereFrom ?? '-'),
          InfoLine(label: 'Narxi', value: formatPrice(tool.price)),
          InfoLine(
            label: 'Hozirgi qiymati',
            value: formatPrice(tool.currentValue),
          ),
          InfoLine(
            label: 'Hozirgi joylashuvi',
            value: tool.currentPlace ?? '-',
          ),
          InfoLine(label: "Jihoz ta'rifi", value: tool.description ?? '-'),
        ],
      ),
    );
  }
}

class _InWarehouseNotice extends StatelessWidget {
  const _InWarehouseNotice();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      blur: 0,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.inventory_2_rounded, color: AppColors.accentGlow),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Bu jihoz hozir omborda turibdi. Uni bo'limga yoki xodimga "
              'berish veb-sahifadagi "Chiqim qilish" bo\'limida bajariladi.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
