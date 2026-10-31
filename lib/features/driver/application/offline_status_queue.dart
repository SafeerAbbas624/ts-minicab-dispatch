import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/driver_repository.dart';

/// A job step the driver tapped while the phone had no signal.
class PendingStatus {
  PendingStatus({required this.jobId, required this.status, required this.tappedAt});

  factory PendingStatus.fromJson(Map<String, dynamic> j) =>
      PendingStatus(jobId: j['job_id'] as String, status: j['status'] as String, tappedAt: DateTime.parse(j['tapped_at'] as String));

  final String jobId;
  final String status;
  final DateTime tappedAt;

  Map<String, dynamic> toJson() => {'job_id': jobId, 'status': status, 'tapped_at': tappedAt.toUtc().toIso8601String()};
}

/// Arrived / passenger on board / complete taps made offline are kept here
/// (and on the device, so a restart doesn't lose them) and sent in order,
/// with the time they were tapped, as soon as the connection returns. The
/// booking audit log then shows both the tap time and when it reached us —
/// TfL's "no data connectivity" scenario.
class OfflineStatusQueue extends ChangeNotifier {
  OfflineStatusQueue(this._repository, this._storage) {
    _load();
  }

  final DriverRepository _repository;
  final SecureStorage _storage;
  final List<PendingStatus> _items = [];
  bool _flushing = false;

  List<PendingStatus> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;

  /// The step this job has reached on the device, if ahead of the server.
  String? latestFor(String jobId) {
    for (final p in _items.reversed) {
      if (p.jobId == jobId) return p.status;
    }
    return null;
  }

  Future<void> enqueue(String jobId, String status) async {
    _items.add(PendingStatus(jobId: jobId, status: status, tappedAt: DateTime.now()));
    notifyListeners();
    await _save();
  }

  /// Sends queued steps oldest first. Stops at the first network failure
  /// (still offline); a 409 means the server already moved past that step,
  /// so it's dropped. Returns true if anything was sent.
  Future<bool> flush() async {
    if (_flushing || _items.isEmpty) return false;
    _flushing = true;
    var sent = false;
    try {
      while (_items.isNotEmpty) {
        final p = _items.first;
        try {
          await _repository.updateJobStatus(p.jobId, status: p.status, clientTime: p.tappedAt);
          sent = true;
        } on ApiException catch (e) {
          if (e.isNetworkError) break;
          debugPrint('[offline-queue] dropped ${p.status} for ${p.jobId}: ${e.message}');
        }
        _items.removeAt(0);
        await _save();
        notifyListeners();
      }
    } finally {
      _flushing = false;
    }
    return sent;
  }

  Future<void> _load() async {
    try {
      final raw = await _storage.readPendingStatuses();
      if (raw == null || raw.isEmpty) return;
      _items
        ..clear()
        ..addAll((jsonDecode(raw) as List).cast<Map<String, dynamic>>().map(PendingStatus.fromJson));
      notifyListeners();
    } catch (e) {
      debugPrint('[offline-queue] could not read saved steps: $e');
    }
  }

  Future<void> _save() => _storage.savePendingStatuses(jsonEncode(_items.map((p) => p.toJson()).toList()));
}

final offlineStatusQueueProvider = ChangeNotifierProvider<OfflineStatusQueue>((ref) {
  return OfflineStatusQueue(ref.watch(driverRepositoryProvider), ref.watch(secureStorageProvider));
});
