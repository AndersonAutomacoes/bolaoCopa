import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/bolao_api.dart';
import '../models/user_profile_dto.dart';
import '../router/app_router.dart';
import 'user_profile_avatar.dart';

/// Menu «Conta» da AppBar com foto do perfil (ou iniciais).
class ProfileAccountMenuButton extends StatefulWidget {
  const ProfileAccountMenuButton({super.key});

  @override
  State<ProfileAccountMenuButton> createState() => _ProfileAccountMenuButtonState();
}

class _ProfileAccountMenuButtonState extends State<ProfileAccountMenuButton> {
  late Future<UserProfileDto> _future;

  @override
  void initState() {
    super.initState();
    _future = BolaoApi.fetchProfile();
  }

  void _reload() {
    setState(() {
      _future = BolaoApi.fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<String>(
        tooltip: 'Conta',
        onOpened: _reload,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: FutureBuilder<UserProfileDto>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(
                  width: 36,
                  height: 36,
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
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
                  radius: 18,
                  backgroundColor: scheme.primaryContainer,
                  foregroundColor: scheme.onPrimaryContainer,
                  child: const Icon(Icons.person, size: 22),
                );
              }
              return UserProfileAvatarDisplay(
                profile: snapshot.data!,
                radius: 18,
              );
            },
          ),
        ),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'inicio',
            child: ListTile(
              leading: Icon(Icons.home_outlined),
              title: Text('Início'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const PopupMenuItem(
            value: 'palpites',
            child: ListTile(
              leading: Icon(Icons.edit_note_outlined),
              title: Text('Meus palpites'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const PopupMenuItem(
            value: 'perfil',
            child: ListTile(
              leading: Icon(Icons.person_outline),
              title: Text('Perfil'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
        onSelected: (v) {
          if (v == 'inicio') context.go(AppRoutes.inicio);
          if (v == 'palpites') context.push(AppRoutes.meusPalpites);
          if (v == 'perfil') context.go(AppRoutes.perfil);
        },
      ),
    );
  }
}
