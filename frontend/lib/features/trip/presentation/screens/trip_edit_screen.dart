import 'package:context_app/features/trip/domain/models/trip.dart';
import 'package:context_app/features/trip/providers/trip_providers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

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

      final trip = existing != null
          ? existing.copyWith(
              name: _nameController.text.trim(),
              startDate: _startDate,
              endDate: _endDate,
            )
          : Trip(
              id: const Uuid().v4(),
              name: _nameController.text.trim(),
              startDate: _startDate,
              endDate: _endDate,
              createdAt: DateTime.now(),
            );

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
    final picked = await showDatePicker(
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
          ? const Center(child: CircularProgressIndicator())
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    final df = DateFormat.yMd();
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'trip.name_label'.tr(),
                hintText: 'trip.name_hint'.tr(),
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'trip.name_required'.tr();
                }
                return null;
              },
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
            const SizedBox(height: 8),
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
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _isEditMode
                          ? 'trip.save_changes'.tr()
                          : 'trip.create_action'.tr(),
                    ),
            ),
          ],
        ),
      ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: onClear == null
              ? const Icon(Icons.calendar_today)
              : IconButton(icon: const Icon(Icons.clear), onPressed: onClear),
        ),
        child: Text(
          value == null ? 'trip.date_not_set'.tr() : formatter.format(value!),
        ),
      ),
    );
  }
}
