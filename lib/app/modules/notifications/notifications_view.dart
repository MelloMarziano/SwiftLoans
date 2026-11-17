import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/services/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/motion.dart';
import '../root/root_controller.dart';
import '../root/widgets/app_shell.dart';

const _amber = Color(0xFFB7791F);
const _amberSoft = Color(0xFFFBF0DC);

/// Filtros de la lista.
enum _Filter { all, unread, cobros, prestamos, cuadre }

extension on _Filter {
  String get label => switch (this) {
    _Filter.all => 'Todas',
    _Filter.unread => 'Sin leer',
    _Filter.cobros => 'Cobros',
    _Filter.prestamos => 'Préstamos',
    _Filter.cuadre => 'Cuadre',
  };

  bool includes(AppNotification n, bool read) => switch (this) {
    _Filter.all => true,
    _Filter.unread => !read,
    _Filter.cobros => n.kind.group == 'Cobros',
    _Filter.prestamos => n.kind.group == 'Préstamos',
    _Filter.cuadre => n.kind.group == 'Cuadre',
  };
}

(IconData, Color, Color) _styleOf(AppNotification n) => switch (n.kind) {
  NotificationKind.dueToday => (
    LucideIcons.coins,
    AppColors.success,
    AppColors.successSoft,
  ),
  NotificationKind.overdue => (
    LucideIcons.clockAlert,
    AppColors.danger,
    AppColors.dangerSoft,
  ),
  NotificationKind.paidOff => (
    LucideIcons.badgeCheck,
    AppColors.primary,
    AppColors.accentSoft,
  ),
  NotificationKind.newLoan => (LucideIcons.handCoins, _amber, _amberSoft),
  NotificationKind.fund => (
    LucideIcons.piggyBank,
    AppColors.primary,
    AppColors.accentSoft,
  ),
  NotificationKind.closingReviewed => (
    LucideIcons.clipboardCheck,
    AppColors.success,
    AppColors.successSoft,
  ),
  NotificationKind.closingPending =>
    n.urgent
        ? (LucideIcons.clipboardList, AppColors.danger, AppColors.dangerSoft)
        : (LucideIcons.clipboardList, _amber, _amberSoft),
  NotificationKind.closingMissing => (
    LucideIcons.clipboardX,
    AppColors.danger,
    AppColors.dangerSoft,
  ),
};

/// Avisos del día: cobros, atrasos, préstamos y cuadres.
class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  final _service = Get.find<NotificationService>();
  var _filter = _Filter.all;

  void _open(AppNotification n) {
    _service.markRead(n);
    if (n.route != null) Get.toNamed(n.route!, arguments: n.arguments);
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Notificaciones',
      showBack: true,
      activeTab: RootController.none,
      actions: [
        Obx(
          () => IconButton(
            tooltip: 'Marcar todo como leído',
            onPressed: _service.unreadCount == 0 ? null : _service.markAllRead,
            icon: const Icon(LucideIcons.checkCheck, size: 20),
          ),
        ),
      ],
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = context.isCompact;
          final side = math.max(
            compact ? 14.0 : 32.0,
            (constraints.maxWidth - 760) / 2,
          );

          return Obx(() {
            final all = _service.notifications;
            final visible = [
              for (final n in all)
                if (_filter.includes(n, _service.isRead(n))) n,
            ];
            final groups = <DateTime, List<AppNotification>>{};
            for (final n in visible) {
              final d = DateTime(n.date.year, n.date.month, n.date.day);
              groups.putIfAbsent(d, () => []).add(n);
            }

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(side, 14, side, 6),
                  sliver: SliverToBoxAdapter(
                    child: SizedBox(
                      height: context.sized(38.0, 42.0),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _Filter.values.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final f = _Filter.values[i];
                          final count = all
                              .where((n) => f.includes(n, _service.isRead(n)))
                              .length;
                          final selected = f == _filter;
                          return ChoiceChip(
                            label: Text('${f.label} ($count)'),
                            selected: selected,
                            onSelected: (_) => setState(() => _filter = f),
                            showCheckmark: false,
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.surface,
                            side: BorderSide(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                            shape: const StadiumBorder(),
                            labelStyle: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                if (visible.isEmpty)
                  SliverToBoxAdapter(
                    child: EmptyState(
                      icon: LucideIcons.bellOff,
                      title: _filter == _Filter.unread
                          ? 'Todo leído'
                          : 'Sin notificaciones',
                      message: 'Aquí verás cobros, atrasos y cuadres.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      side,
                      8,
                      side,
                      compact ? 120 : 32,
                    ),
                    sliver: SliverList.separated(
                      itemCount: groups.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                      itemBuilder: (_, i) {
                        final entry = groups.entries.elementAt(i);
                        return _DayGroup(
                          key: ValueKey(entry.key),
                          day: entry.key,
                          today: _service.now,
                          items: entry.value,
                          isRead: _service.isRead,
                          onTap: _open,
                        ).entrance(i);
                      },
                    ),
                  ),
              ],
            );
          });
        },
      ),
    );
  }
}

class _DayGroup extends StatelessWidget {
  const _DayGroup({
    super.key,
    required this.day,
    required this.today,
    required this.items,
    required this.isRead,
    required this.onTap,
  });

  final DateTime day;
  final DateTime today;
  final List<AppNotification> items;
  final bool Function(AppNotification) isRead;
  final ValueChanged<AppNotification> onTap;

  static const _weekdays = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  String get _label {
    final t = DateTime(today.year, today.month, today.day);
    if (day == t) return 'Hoy';
    if (day == t.subtract(const Duration(days: 1))) return 'Ayer';
    return '${_weekdays[day.weekday - 1]}, ${DateFormat('dd/MM').format(day)}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(
            _label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, indent: 64, color: AppColors.border),
                _NotificationTile(
                  notification: items[i],
                  read: isRead(items[i]),
                  onTap: () => onTap(items[i]),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.read,
    required this.onTap,
  });

  final AppNotification notification;
  final bool read;
  final VoidCallback onTap;

  static final _time = DateFormat('h:mm a');

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final (icon, color, soft) = _styleOf(n);

    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.fast,
        color: read ? Colors.transparent : const Color(0xFFF2FBFC),
        padding: EdgeInsets.symmetric(
          horizontal: context.sized(12, 16),
          vertical: context.sized(12, 14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: soft, shape: BoxShape.circle),
              child: Icon(icon, size: 19, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          style: TextStyle(
                            fontSize: context.sized(14.5, 15.5),
                            fontWeight: read
                                ? FontWeight.w600
                                : FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _time.format(n.date),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    n.body,
                    style: TextStyle(
                      color: n.urgent && !read
                          ? AppColors.danger
                          : AppColors.textSecondary,
                      fontSize: context.sized(12.5, 13.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedOpacity(
              duration: Motion.fast,
              opacity: read ? 0 : 1,
              child: Container(
                width: 9,
                height: 9,
                margin: const EdgeInsets.only(top: 6),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
