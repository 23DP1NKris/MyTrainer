// Temporary demo screen that proves the Supabase connection works.
// Not part of the real UI; remove once proper screens exist.
// Reads public.demo_overview(), which is callable without signing in.
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient get _db => Supabase.instance.client;

const _roles = {
  'user': 'Lietotājs',
  'moderator': 'Moderators',
  'admin': 'Administrators',
};

const _statuses = {
  'active': 'Aktīvs',
  'blocked': 'Bloķēts',
};

class DbDemoPage extends StatefulWidget {
  const DbDemoPage({super.key});

  @override
  State<DbDemoPage> createState() => _DbDemoPageState();
}

class _DbDemoPageState extends State<DbDemoPage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await _db.rpc('demo_overview');
      setState(() {
        _data = Map<String, dynamic>.from(result as Map);
        _error = null;
      });
    } on PostgrestException catch (e) {
      setState(() => _error = e.code == 'PGRST202'
          ? 'Funkcija demo_overview datubāzē nav atrasta. '
              'Palaid SQL Supabase SQL Editor un mēģini vēlreiz.\n\n${e.message}'
          : e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _dateTime(String? iso, {bool withTime = false}) {
    if (iso == null) return '—';
    final t = DateTime.parse(iso).toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    final date = '${two(t.day)}.${two(t.month)}.${t.year}';
    return withTime ? '$date ${two(t.hour)}:${two(t.minute)}' : date;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MyTrainer – DB demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                children: _error != null ? [_errorCard()] : _content(),
              ),
            ),
    );
  }

  Widget _errorCard() {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Neizdevās ielādēt datus no Supabase',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                setState(() => _loading = true);
                _load();
              },
              child: const Text('Mēģināt vēlreiz'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _content() {
    final d = _data!;
    final users = List<Map<String, dynamic>>.from(
        (d['users'] as List? ?? []).map((u) => Map<String, dynamic>.from(u)));

    return [
      Card(
        color: Colors.green.shade100,
        child: ListTile(
          leading: const Icon(Icons.check_circle, color: Colors.green),
          title: const Text('Savienots ar Supabase ✓'),
          subtitle: Text(
              'Servera laiks: ${_dateTime(d['server_time'] as String?, withTime: true)}'),
        ),
      ),
      Row(
        children: [
          Expanded(child: _countCard('Vingrinājumi', d['exercise_count'])),
          Expanded(child: _countCard('Programmas', d['program_count'])),
          Expanded(child: _countCard('Lietotāji', users.length)),
        ],
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: Text('Lietotāji datubāzē',
            style: Theme.of(context).textTheme.titleMedium),
      ),
      if (users.isEmpty)
        const Card(child: ListTile(title: Text('Vēl nav neviena lietotāja'))),
      for (final u in users)
        Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text(((u['username'] as String?)?.isNotEmpty ?? false)
                  ? (u['username'] as String)[0].toUpperCase()
                  : '?'),
            ),
            title: Text(u['username'] as String? ?? '(nav lietotājvārda)'),
            subtitle: Text(
                '${_roles[u['role']] ?? u['role'] ?? '—'} · '
                '${_statuses[u['status']] ?? u['status'] ?? '—'}\n'
                'Reģistrēts: ${_dateTime(u['created_at'] as String?)}'),
            isThreeLine: true,
          ),
        ),
    ];
  }

  Widget _countCard(String label, Object? value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text('${value ?? '—'}',
                style: Theme.of(context).textTheme.headlineMedium),
            Text(label),
          ],
        ),
      ),
    );
  }
}
