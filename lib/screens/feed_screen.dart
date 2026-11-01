import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/post.dart';
import '../providers/connectivity_provider.dart';
import '../providers/feed_provider.dart';
import '../services/analytics_service.dart';
import '../widgets/common/feedback.dart';
import '../widgets/common/hamtimer_app_bar.dart';
import '../widgets/common/message_state.dart';
import '../widgets/feed/post_card.dart';

/// Pantalla f) Feed: fotos con filtro de todos los usuarios, en vivo desde
/// Firestore (las imágenes viven en Storage), con likes.
///
/// Es lo único de la app que necesita internet: sin conexión muestra un aviso.
class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  Future<void> _toggleLike(BuildContext context, Post post) async {
    final feed = context.read<FeedProvider>();
    final analytics = context.read<AnalyticsService>();
    final liked = !post.isLikedBy(feed.currentUid ?? '');
    try {
      await feed.toggleLike(post);
      await analytics.logEvent(liked ? 'post_liked' : 'post_unliked', {'filter': post.filterId});
    } on Exception {
      if (context.mounted) AppFeedback.show(context, 'No se pudo guardar el like');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = context.select<ConnectivityProvider, bool>((c) => c.isOnline);
    final feed = context.watch<FeedProvider>();

    return Column(
      children: [
        const HamtimerAppBar(
          title: 'Feed',
          subtitle: 'Las fotos con filtro de la comunidad',
          centerTitle: false,
        ),
        Expanded(child: _buildBody(context, feed, isOnline)),
      ],
    );
  }

  Widget _buildBody(BuildContext context, FeedProvider feed, bool isOnline) {
    if (!isOnline) {
      return const MessageState(
        icon: Icons.wifi_off_rounded,
        message: 'Sin conexión.\nEl feed necesita internet; el resto de la app sigue funcionando.',
      );
    }
    if (feed.isLoading) return const Center(child: CircularProgressIndicator());
    if (feed.errorMessage != null) {
      return MessageState(
        icon: Icons.cloud_off_outlined,
        message: feed.errorMessage!,
        actionLabel: 'Reintentar',
        onAction: feed.retry,
      );
    }
    if (feed.posts.isEmpty) {
      return const MessageState(
        icon: Icons.photo_library_outlined,
        message: 'Todavía no hay fotos.\nToma la primera en la pestaña "Cámara".',
      );
    }

    final now = DateTime.now();
    final uid = feed.currentUid ?? '';
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: feed.posts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        final post = feed.posts[index];
        return PostCard(
          key: ValueKey(post.id),
          post: post,
          isLiked: post.isLikedBy(uid),
          now: now,
          onLike: () => _toggleLike(context, post),
        );
      },
    );
  }
}
