import 'package:flutter/material.dart';

import '../models/ranking_item_dto.dart';
import '../models/user_profile_dto.dart';
import '../theme/app_theme.dart';
import 'user_profile_avatar.dart';

/// Linha de ranking alinhada ao mockup: pódio com medalhas, fundo suave no top 3, tabela compacta.
class RankingRankRow extends StatelessWidget {
  const RankingRankRow({super.key, required this.item});

  final RankingItemDto item;

  static const Color _goldRow = Color(0xFFFFFBEB);
  static const Color _silverRow = Color(0xFFEFF6FF);
  static const Color _bronzeRow = Color(0xFFFFF7ED);

  static const Color _goldMedal = Color(0xFFEAB308);
  static const Color _silverMedal = Color(0xFF94A3B8);
  static const Color _bronzeMedal = Color(0xFFB45309);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final pos = item.posicao;
    final isTop = pos >= 1 && pos <= 3;
    final name = item.nome?.isNotEmpty == true ? item.nome! : item.email;
    final handle = _emailHandle(item.email);
    final profileForAvatar = UserProfileDto(
      userId: item.userId,
      email: item.email,
      fullName: name,
      idade: 0,
      sexo: '',
      telefone: '',
      avatarUrl: item.avatarUrl,
    );

    Color? rowTint;
    if (pos == 1) rowTint = _goldRow;
    if (pos == 2) rowTint = _silverRow;
    if (pos == 3) rowTint = _bronzeRow;

    Widget posCell;
    if (pos == 1) {
      posCell = const Icon(Icons.emoji_events, color: _goldMedal, size: 28);
    } else if (pos == 2) {
      posCell = const Icon(Icons.emoji_events, color: _silverMedal, size: 28);
    } else if (pos == 3) {
      posCell = const Icon(Icons.emoji_events, color: _bronzeMedal, size: 28);
    } else {
      posCell = CircleAvatar(
        radius: 18,
        backgroundColor: scheme.surfaceContainerHighest,
        child: Text(
          '$pos',
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      );
    }

    return Material(
      color: rowTint ?? scheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.outlineMuted.withValues(alpha: 0.65)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: 44, child: Center(child: posCell)),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    UserProfileAvatarDisplay(profile: profileForAvatar, radius: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isTop && handle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              handle,
                              style: textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 56,
              child: Text(
                '${item.totalPontos}',
                textAlign: TextAlign.end,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            SizedBox(
              width: 72,
              child: Text(
                '${item.totalAcertosExatos}',
                textAlign: TextAlign.end,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _emailHandle(String email) {
    final i = email.indexOf('@');
    if (i <= 0) return null;
    return '@${email.substring(0, i)}';
  }
}
