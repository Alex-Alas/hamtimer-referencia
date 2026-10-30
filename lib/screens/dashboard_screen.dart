import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/errors/app_exception.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/date_labels.dart';
import '../models/task.dart';
import '../models/task_filter.dart';
import '../providers/auth_provider.dart';
import '../providers/pomodoro_provider.dart';
import '../providers/task_provider.dart';
import '../providers/wallet_provider.dart';
import '../services/analytics_service.dart';
import '../widgets/common/feedback.dart';
import '../widgets/common/hamtimer_app_bar.dart';
import '../widgets/common/message_state.dart';
import '../widgets/common/points_chip.dart';
import '../widgets/dashboard/daily_progress_banner.dart';
import '../widgets/dashboard/offline_banner.dart';
import '../widgets/dashboard/task_card.dart';
import '../widgets/dashboard/task_filter_bar.dart';

/// Pantalla b) Dashboard: avance del día, puntos, filtros y la lista de
/// tareas con scroll infinito (GET paginado a MockAPI, caché en SQLite).
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  /// Distancia (px) al final de la lista a la que se pide la siguiente página.
  static const double _loadMoreThreshold = 300;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      context.read<TaskProvider>().loadMore();
    }
  }

  Future<void> _changeFilter(TaskFilter filter) async {
    context.read<AnalyticsService>().logEvent('task_filter_changed', {
      'filter': filter.analyticsName,
    });
    await context.read<TaskProvider>().changeFilter(filter);
  }

  Future<void> _toggleCompleted(Task task) async {
    final analytics = context.read<AnalyticsService>();
    try {
      await context.read<TaskProvider>().toggleCompleted(task);
      await analytics.logEvent('task_toggled', {'completed': (!task.isCompleted).toString()});
    } on AppException catch (error) {
      if (mounted) AppFeedback.show(context, error.message);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Salir')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final auth = context.read<AuthProvider>();
    // La sesión de Pomodoro tiene tareas de este usuario: se limpia al salir.
    context.read<PomodoroProvider>().endSession();
    await context.read<AnalyticsService>().logEvent('logout');
    await auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final points = context.select<WalletProvider, int>((wallet) => wallet.points);
    final name = context.select<AuthProvider, String>((auth) => auth.user?.displayName ?? '');
    final now = DateTime.now();

    return Column(
      children: [
        HamtimerAppBar(
          title: name.isEmpty ? 'Hamtimer' : 'Hola, $name',
          subtitle: DateLabels.todayHeader(now),
          centerTitle: false,
          leading: AppBarIconButton(
            icon: Icons.logout,
            tooltip: 'Cerrar sesión',
            onPressed: _signOut,
          ),
          actions: [PointsChip(points: points)],
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: provider.refresh,
            child: CustomScrollView(
              controller: _scrollController,
              // Siempre desplazable, para que "jalar para recargar" funcione
              // aunque la lista sea corta.
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: _ScreenHeader()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  sliver: SliverToBoxAdapter(
                    child: DailyProgressBanner(progress: provider.todayProgress),
                  ),
                ),
                if (provider.isOffline)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                    sliver: SliverToBoxAdapter(
                      child: OfflineBanner(
                        pendingSync: provider.pendingSync,
                        onRetry: provider.refresh,
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: TaskFilterBar(selected: provider.filter, onSelected: _changeFilter),
                ),
                ..._buildListSlivers(provider, now),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Decide qué mostrar según el estado de la carga: cargando, error, vacío o
  /// la lista (con un indicador al final mientras llega la siguiente página).
  List<Widget> _buildListSlivers(TaskProvider provider, DateTime now) {
    if (provider.isLoading && provider.tasks.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (provider.errorMessage != null && provider.tasks.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: MessageState(
            icon: Icons.cloud_off_outlined,
            message: provider.errorMessage!,
            actionLabel: 'Reintentar',
            onAction: provider.refresh,
          ),
        ),
      ];
    }

    if (provider.tasks.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: MessageState(
            icon: Icons.inbox_outlined,
            message: 'No hay tareas aquí todavía.\nCrea una en la pestaña "Nueva".',
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        sliver: SliverList.separated(
          itemCount: provider.tasks.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final task = provider.tasks[index];
            return TaskCard(
              key: ValueKey(task.id),
              task: task,
              now: now,
              onToggleCompleted: () => _toggleCompleted(task),
            );
          },
        ),
      ),
      if (provider.isLoadingMore)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
    ];
  }
}

class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mis tareas',
            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            'Completa Pomodoros para ganar puntos',
            style: textTheme.labelMedium?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
