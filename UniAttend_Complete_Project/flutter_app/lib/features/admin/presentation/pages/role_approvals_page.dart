import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/services/api_service.dart';

class RoleApprovalsPage extends StatefulWidget {
  const RoleApprovalsPage({super.key});

  @override
  State<RoleApprovalsPage> createState() => _RoleApprovalsPageState();
}

class _RoleApprovalsPageState extends State<RoleApprovalsPage> {
  late Future<List<Map<String, dynamic>>> _pendingFuture;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _pendingFuture = _loadPending();
  }

  Future<List<Map<String, dynamic>>> _loadPending() async {
    final api = GetIt.I<ApiService>();
    final res = await api.get('/admin/role-applications',
        queryParameters: {'status': 'pending'});
    final list = (res['applications'] as List<dynamic>? ?? const []);
    return list.whereType<Map<String, dynamic>>().toList();
  }

  Future<void> _review(String id, bool approve) async {
    setState(() => _busy = true);
    final api = GetIt.I<ApiService>();
    try {
      await api.post(
        '/admin/role-applications/$id/${approve ? 'approve' : 'reject'}',
        data: {},
      );
      if (!mounted) return;
      setState(() {
        _pendingFuture = _loadPending();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                approve ? 'Application approved.' : 'Application rejected.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Review failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Role Applications')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _pendingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Failed to load applications: ${snapshot.error}'));
          }

          final items = snapshot.data ?? const <Map<String, dynamic>>[];
          if (items.isEmpty) {
            return const Center(child: Text('No pending role applications.'));
          }

          return Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final app = items[i];
                  final id = (app['id'] ?? '').toString();
                  final requestedRole =
                      (app['requested_role'] ?? '').toString();
                  final name = (app['full_name'] ?? '-').toString();
                  final email = (app['email'] ?? '-').toString();
                  final matric = (app['matric_number'] ?? '-').toString();
                  final dept = (app['department'] ?? '-').toString();
                  final createdAt = (app['created_at'] ?? '-').toString();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text('$email • $matric • $dept',
                              style: const TextStyle(
                                  color: AppTheme.textSecondary)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryNavy.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('Requested: $requestedRole',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                              ),
                              const Spacer(),
                              Text(createdAt,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed:
                                      _busy ? null : () => _review(id, false),
                                  icon: const Icon(Icons.close),
                                  label: const Text('Reject'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _busy ? null : () => _review(id, true),
                                  icon: const Icon(Icons.check),
                                  label: const Text('Approve'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              if (_busy)
                const Align(
                  alignment: Alignment.topCenter,
                  child: LinearProgressIndicator(),
                ),
            ],
          );
        },
      ),
    );
  }
}
