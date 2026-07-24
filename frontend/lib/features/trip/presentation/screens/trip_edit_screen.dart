import 'package:context_app/app/config/lorescape_tokens.dart';
import 'package:context_app/features/trip/domain/models/trip.dart';
import 'package:context_app/features/trip/providers.dart';
import 'package:context_app/shared/widgets/journal/lorescape_date_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:context_app/shared/widgets/adaptive/adaptive_widgets.dart';

/// 建立或編輯 Trip 的表單頁。
///
/// 傳入 [tripId] 代表編輯模式；否則為新建模式。
class TripEditScreen extends ConsumerStatefulWidget {
  final String? tripId;

  const TripEditScreen({super.key, this.tripId});

  @override
  ConsumerState<TripEditScreen> createState() => _TripEditScreenState();
}

class _TripEditScreenState extends ConsumerState<TripEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _saving = false;
  bool _loadingInitial = false;

  bool get _isEditMode => widget.tripId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _loadingInitial = true;
      _loadExistingTrip();
    }
  }

  Future<void> _loadExistingTrip() async {
    final trip = await ref.read(tripRepositoryProvider).getById(widget.tripId!);
    if (!mounted) return;
    setState(() {
      if (trip != null) {
        _nameController.text = trip.name;
        _startDate = trip.startDate;
        _endDate = trip.endDate;
      }
      _loadingInitial = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final repo = ref.read(tripRepositoryProvider);
      final existing = _isEditMode ? await repo.getById(widget.tripId!) : null;

      final Trip trip;
      if (existing != null) {
        trip = existing.copyWith(
          name: _nameController.text.trim(),
          startDate: _startDate,
          endDate: _endDate,
        );
      } else {
        final now = DateTime.now();
        trip = Trip(
          id: const Uuid().v4(),
          name: _nameController.text.trim(),
          startDate: _startDate,
          endDate: _endDate,
          createdAt: now,
          updatedAt: now,
        );
      }

      await repo.save(trip);

      ref.invalidate(tripsProvider);
      if (_isEditMode) {
        ref.invalidate(tripByIdProvider(widget.tripId!));
      }

      if (!mounted) return;
      context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? _startDate ?? DateTime.now());
    final picked = await showLorescapeDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'trip.edit_title'.tr() : 'trip.create_title'.tr(),
        ),
      ),
      body: _loadingInitial
          ? const Center(child: AdaptiveProgressIndicator())
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    final df = DateFormat.yMd();
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
        children: [
          _FieldBox(
            label: 'trip.name_label'.tr(),
            child: TextFormField(
              controller: _nameController,
              style: TextStyle(
                fontSize: 17,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              // The field sits inside _FieldBox, so it must fully opt out of
              // the global outlined+filled inputDecorationTheme. Clearing only
              // `border` leaves enabledBorder/focusedBorder (and the fill)
              // drawing a nested box.
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: 'trip.name_hint'.tr(),
                hintStyle: TextStyle(
                  fontSize: 17,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'trip.name_required'.tr();
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),
          _DatePickerTile(
            label: 'trip.start_date'.tr(),
            value: _startDate,
            formatter: df,
            onTap: () => _pickDate(isStart: true),
            onClear: _startDate == null
                ? null
                : () => setState(() => _startDate = null),
          ),
          const SizedBox(height: 16),
          _DatePickerTile(
            label: 'trip.end_date'.tr(),
            value: _endDate,
            formatter: df,
            onTap: () => _pickDate(isStart: false),
            onClear: _endDate == null
                ? null
                : () => setState(() => _endDate = null),
          ),
          const SizedBox(height: 32),
          AdaptiveButton(
            expanded: true,
            padding: const EdgeInsets.symmetric(vertical: 16),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: AdaptiveProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _isEditMode
                        ? 'trip.save_changes'.tr()
                        : 'trip.create_action'.tr(),
                  ),
          ),
        ],
      ),
    );
  }
}

/// A Field Journal `.field` box: a paper-raised container with a small top
/// label and arbitrary content below.
class _FieldBox extends StatelessWidget {
  const _FieldBox({required this.label, required this.child, this.onTap});

  final String label;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<LorescapeTokens>();
    final ink3 = tokens?.ink3 ?? cs.onSurfaceVariant;
    final radius = context.tokens.rMd;

    final content = Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(radius),
        border: Border.fromBorderSide(BorderSide(color: cs.outlineVariant)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: ink3,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: content,
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  final String label;
  final DateTime? value;
  final DateFormat formatter;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DatePickerTile({
    required this.label,
    required this.value,
    required this.formatter,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<LorescapeTokens>();
    final ink3 = tokens?.ink3 ?? cs.onSurfaceVariant;
    return _FieldBox(
      label: label,
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Text(
              value == null
                  ? 'trip.date_not_set'.tr()
                  : formatter.format(value!),
              style: TextStyle(
                fontSize: 17,
                color: value == null ? ink3 : cs.onSurface,
              ),
            ),
          ),
          if (onClear == null)
            Icon(Icons.calendar_today_outlined, size: 20, color: ink3)
          else
            GestureDetector(
              onTap: onClear,
              behavior: HitTestBehavior.opaque,
              child: Icon(Icons.clear, size: 20, color: ink3),
            ),
        ],
      ),
    );
  }
}
