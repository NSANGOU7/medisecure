import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../services/appointment_service.dart';
import '../../models/appointment_model.dart';
import '../../widgets/appointment_card.dart';
import '../../widgets/section_header.dart';

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});
  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  List<AppointmentModel> _filter(List<AppointmentModel> all, String status) {
    if (status == 'upcoming') {
      return all.where((a) => !a.isCancelled && a.dateRdv.isAfter(DateTime.now())).toList()
        ..sort((a, b) => a.dateRdv.compareTo(b.dateRdv));
    }
    if (status == 'past') {
      return all.where((a) => a.dateRdv.isBefore(DateTime.now()) || a.isCompleted).toList()
        ..sort((a, b) => b.dateRdv.compareTo(a.dateRdv));
    }
    return all.where((a) => a.isCancelled).toList();
  }

  @override
  Widget build(BuildContext context) {
    final apptAsync = ref.watch(appointmentsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: const Color(0xFF1A56DB),
            title: const Text('Rendez-vous'),
            bottom: TabBar(
              controller: _tabs,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: Colors.white,
              tabs: const [
                Tab(text: 'À venir'),
                Tab(text: 'Passés'),
                Tab(text: 'Annulés'),
              ],
            ),
          ),
          // Week calendar strip
          SliverToBoxAdapter(
            child: Container(
              color: const Color(0xFF1A56DB),
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: _WeekStrip(
                selected: _selectedDay,
                onSelect: (d) => setState(() => _selectedDay = d),
              ),
            ),
          ),
        ],
        body: apptAsync.when(
          data: (appts) => TabBarView(
            controller: _tabs,
            children: [
              _ApptList(appts: _filter(appts, 'upcoming')),
              _ApptList(appts: _filter(appts, 'past')),
              _ApptList(appts: _filter(appts, 'cancelled')),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur: $e')),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/appointments/book'),
        backgroundColor: const Color(0xFF1A56DB),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Prendre RDV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;
  const _WeekStrip({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final now   = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final days  = List.generate(7, (i) => start.add(Duration(days: i)));
    return Row(
      children: days.map((d) {
        final isSelected = d.day == selected.day && d.month == selected.month;
        final isToday    = d.day == now.day && d.month == now.month;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(d),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : (isToday ? Colors.white24 : Colors.transparent),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(children: [
                Text(DateFormat('E', 'fr').format(d).substring(0, 3),
                    style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: isSelected ? const Color(0xFF1A56DB) : Colors.white70,
                    )),
                const SizedBox(height: 4),
                Text('${d.day}',
                    style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: isSelected ? const Color(0xFF1A56DB) : Colors.white,
                    )),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ApptList extends StatelessWidget {
  final List<AppointmentModel> appts;
  const _ApptList({required this.appts});

  @override
  Widget build(BuildContext context) {
    if (appts.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.event_available_outlined, size: 64, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 12),
          const Text('Aucun rendez-vous', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => context.push('/appointments/book'),
            icon: const Icon(Icons.add),
            label: const Text('Prendre un RDV'),
          ),
        ]),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: appts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => AppointmentCard(
        appointment: appts[i],
        onTap: () => context.push('/appointments/${appts[i].id}'),
      ),
    );
  }
}
