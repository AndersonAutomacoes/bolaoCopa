import 'package:flutter/material.dart';

import '../api/bolao_api.dart';
import '../formatting/profile_labels.dart';
import '../models/user_profile_dto.dart';

/// Avatar circular do utilizador: URL da API ou iniciais do nome.
class UserProfileAvatarDisplay extends StatelessWidget {
  const UserProfileAvatarDisplay({
    super.key,
    required this.profile,
    this.radius = 18,
  });

  final UserProfileDto profile;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final initials = profileInitialsFromName(profile.fullName);
    final displayInitials = initials.length >= 2 ? initials.substring(0, 2) : initials;
    final u = profile.avatarUrl?.trim();
    final size = radius * 2;

    if (u != null && u.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          u,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _FallbackAvatar(
            radius: radius,
            scheme: scheme,
            t: t,
            initials: displayInitials,
          ),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return SizedBox(
              width: size,
              height: size,
              child: Center(
                child: SizedBox(
                  width: radius,
                  height: radius,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.primary,
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return _FallbackAvatar(
      radius: radius,
      scheme: scheme,
      t: t,
      initials: displayInitials,
    );
  }
}

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar({
    required this.radius,
    required this.scheme,
    required this.t,
    required this.initials,
  });

  final double radius;
  final ColorScheme scheme;
  final TextTheme t;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      child: Text(
        initials,
        style: t.labelLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

/// Carrega o perfil e mostra o avatar (para AppBar / admin).
class UserProfileAvatarLoader extends StatefulWidget {
  const UserProfileAvatarLoader({
    super.key,
    this.radius = 18,
    this.onProfileLoaded,
  });

  final double radius;
  final void Function(UserProfileDto profile)? onProfileLoaded;

  @override
  State<UserProfileAvatarLoader> createState() => _UserProfileAvatarLoaderState();
}

class _UserProfileAvatarLoaderState extends State<UserProfileAvatarLoader> {
  late Future<UserProfileDto> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<UserProfileDto> _load() async {
    final p = await BolaoApi.fetchProfile();
    widget.onProfileLoaded?.call(p);
    return p;
  }

  void reload() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder<UserProfileDto>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: widget.radius * 2,
            height: widget.radius * 2,
            child: Center(
              child: SizedBox(
                width: widget.radius,
                height: widget.radius,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.primary,
                ),
              ),
            ),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return CircleAvatar(
            radius: widget.radius,
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
            child: const Icon(Icons.person, size: 22),
          );
        }
        return UserProfileAvatarDisplay(
          profile: snapshot.data!,
          radius: widget.radius,
        );
      },
    );
  }
}
