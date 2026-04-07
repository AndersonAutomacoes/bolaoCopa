import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/bolao_api.dart';
import '../../../core/api/error_message.dart';
import '../../../core/models/user_profile_dto.dart';
import '../../../core/formatting/profile_labels.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_detail_skeleton.dart';
import '../../../core/widgets/app_shell_app_bar_actions.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_view.dart';

/// Valores aceitos pelo dropdown; a API pode devolver legados (ex.: `F` em vez de `FEMININO`).
String _sexoDropdownValue(String? raw) {
  const allowed = {'MASCULINO', 'FEMININO', 'OUTRO', 'PREFIRO_NAO_INFORMAR'};
  if (raw == null || raw.isEmpty) return 'PREFIRO_NAO_INFORMAR';
  if (allowed.contains(raw)) return raw;
  switch (raw.toUpperCase()) {
    case 'F':
    case 'FEM':
      return 'FEMININO';
    case 'M':
    case 'MASC':
      return 'MASCULINO';
    case 'O':
      return 'OUTRO';
    default:
      return 'PREFIRO_NAO_INFORMAR';
  }
}

Widget _profileAvatar({
  required String? avatarUrl,
  required String initials,
  required TextTheme t,
  required ColorScheme scheme,
}) {
  final u = avatarUrl?.trim();
  if (u != null && u.isNotEmpty) {
    return ClipOval(
      child: Image.network(
        u,
        width: 104,
        height: 104,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => CircleAvatar(
          radius: 52,
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          child: Text(
            initials,
            style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: 104,
            height: 104,
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
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
  return CircleAvatar(
    radius: 52,
    backgroundColor: scheme.primaryContainer,
    foregroundColor: scheme.onPrimaryContainer,
    child: Text(
      initials,
      style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
    ),
  );
}

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  late Future<UserProfileDto?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<UserProfileDto?> _load() async {
    try {
      final p = await BolaoApi.fetchProfile();
      AppRouter.auth.syncPlanTierFromProfile(p.planTier);
      return p;
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _logout() async {
    await AppRouter.auth.logout();
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(
            tooltip: 'Ajuda',
            onPressed: () => context.push(AppRoutes.ajuda),
            icon: const Icon(Icons.help_outline),
          ),
          ...AppShellAppBarActions.build(
            context,
            extra: [
              IconButton(onPressed: _reload, icon: const Icon(Icons.refresh), tooltip: 'Atualizar'),
            ],
          ),
        ],
      ),
      body: FutureBuilder<UserProfileDto?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppDetailSkeleton();
          }
          if (snapshot.hasError) {
            return AppErrorView(
              title: 'Não foi possível carregar o perfil',
              message: apiErrorMessage(snapshot.error),
              onPrimary: _reload,
            );
          }
          final profile = snapshot.data;
          if (profile == null) {
            return AppEmptyState(
              title: 'Perfil incompleto',
              subtitle:
                  'Não encontramos seus dados de perfil. Complete os dados ou tente atualizar.',
              icon: Icons.person_outline,
              actionLabel: 'Completar perfil',
              onAction: () => _openEditDialog(context, null),
            );
          }
          final scheme = Theme.of(context).colorScheme;
          final t = Theme.of(context).textTheme;
          final initials = profileInitialsFromName(profile.fullName);

          return ListView(
            padding: AppLayout.pagePaddingHV,
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppLayout.contentMaxWidth),
                  child: Card(
                    elevation: 4,
                    shadowColor: Colors.black.withValues(alpha: 0.08),
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      child: Column(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              _profileAvatar(
                                avatarUrl: profile.avatarUrl,
                                initials: initials,
                                t: t,
                                scheme: scheme,
                              ),
                              Positioned(
                                right: -4,
                                bottom: 0,
                                child: Material(
                                  color: scheme.secondaryContainer,
                                  shape: const CircleBorder(),
                                  child: IconButton(
                                    tooltip: 'Alterar foto',
                                    onPressed: () => _openAvatarDialog(context, profile.avatarUrl),
                                    icon: Icon(Icons.edit_outlined, size: 18, color: scheme.onSecondaryContainer),
                                    padding: const EdgeInsets.all(6),
                                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            profile.fullName,
                            textAlign: TextAlign.center,
                            style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            profile.email,
                            textAlign: TextAlign.center,
                            style: t.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 24),
                          _DarkLabeledField(
                            label: 'Nome completo',
                            value: profile.fullName,
                            onEdit: () => _openEditDialog(context, profile),
                          ),
                          const SizedBox(height: 14),
                          _DarkLabeledField(
                            label: 'E-mail',
                            value: profile.email,
                            onEdit: () => _openEditDialog(context, profile),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Telefone: ${profile.telefone}',
                            textAlign: TextAlign.center,
                            style: t.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Membro desde: ${formatMemberSincePtBr(profile.createdAt)}',
                            textAlign: TextAlign.center,
                            style: t.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Plano: ${formatPlanTierLabel(profile.planTier)} · ${formatRolesLabel(profile.roles)}',
                            textAlign: TextAlign.center,
                            style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _logout,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: AppTheme.textPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.logout, color: AppTheme.textPrimary),
                              label: const Text(
                                'Sair',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (profile.isAdmin)
                FilledButton.icon(
                  onPressed: () => context.push(AppRoutes.admin),
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  label: const Text('Administração'),
                ),
              if (profile.isAdmin) const SizedBox(height: 8),
              if (profile.isPrataOrAbove)
                OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.boloes),
                  icon: const Icon(Icons.groups_outlined),
                  label: const Text('Bolões privados (Prata+)'),
                ),
              if (profile.isPrataOrAbove) const SizedBox(height: 8),
              if (profile.isOuro)
                OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.premiacoes),
                  icon: const Icon(Icons.emoji_events_outlined),
                  label: const Text('Premiação (Ouro)'),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openAvatarDialog(BuildContext context, String? current) async {
    var busy = false;
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Foto do perfil'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Escolha uma imagem no seu dispositivo (JPEG, PNG, GIF ou WebP, até 2 MB).',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: busy
                          ? null
                          : () async {
                              final result = await FilePicker.platform.pickFiles(
                                type: FileType.image,
                                withData: true,
                              );
                              if (result == null || result.files.isEmpty) return;
                              final f = result.files.single;
                              final bytes = f.bytes;
                              if (bytes == null) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Não foi possível ler o ficheiro. Tente outra imagem.'),
                                    ),
                                  );
                                }
                                return;
                              }
                              if (bytes.length > 2 * 1024 * 1024) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Imagem demasiado grande (máx. 2 MB).')),
                                  );
                                }
                                return;
                              }
                              if (BolaoApi.guessImageMimeFromFilename(f.name) == null) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Formato não suportado. Use JPEG, PNG, GIF ou WebP.'),
                                    ),
                                  );
                                }
                                return;
                              }
                              setDialogState(() => busy = true);
                              try {
                                await BolaoApi.uploadProfileAvatar(
                                  fileBytes: bytes,
                                  filename: f.name.isNotEmpty ? f.name : 'avatar.jpg',
                                );
                                if (context.mounted) {
                                  Navigator.pop(ctx);
                                  _reload();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Foto do perfil atualizada.')),
                                  );
                                }
                              } on ApiException catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                                }
                              } on ArgumentError catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.message ?? 'Ficheiro inválido.')),
                                  );
                                }
                              } finally {
                                if (context.mounted) setDialogState(() => busy = false);
                              }
                            },
                      icon: const Icon(Icons.upload_file_outlined),
                      label: busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Escolher imagem'),
                    ),
                    if (current != null && current.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: busy
                            ? null
                            : () async {
                                setDialogState(() => busy = true);
                                try {
                                  await BolaoApi.deleteProfileAvatar();
                                  if (context.mounted) {
                                    Navigator.pop(ctx);
                                    _reload();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Foto do perfil removida.')),
                                    );
                                  }
                                } on ApiException catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                                  }
                                } finally {
                                  if (context.mounted) setDialogState(() => busy = false);
                                }
                              },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Remover foto atual'),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: busy ? null : () => Navigator.pop(ctx), child: const Text('Fechar')),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openEditDialog(BuildContext context, UserProfileDto? existing) async {
    final nameCtrl = TextEditingController(text: existing?.fullName ?? '');
    final idadeCtrl = TextEditingController(text: existing != null ? '${existing.idade}' : '');
    final telCtrl = TextEditingController(text: existing?.telefone ?? '');
    var sexo = _sexoDropdownValue(existing?.sexo);
    var saving = false;

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(existing == null ? 'Completar perfil' : 'Editar perfil'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nome completo'),
                    ),
                    TextField(
                      controller: idadeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Idade'),
                    ),
                    DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: sexo,
                      decoration: const InputDecoration(labelText: 'Sexo'),
                      items: const [
                        DropdownMenuItem(value: 'MASCULINO', child: Text('Masculino')),
                        DropdownMenuItem(value: 'FEMININO', child: Text('Feminino')),
                        DropdownMenuItem(value: 'OUTRO', child: Text('Outro')),
                        DropdownMenuItem(
                          value: 'PREFIRO_NAO_INFORMAR',
                          child: Text('Prefiro não informar'),
                        ),
                      ],
                      onChanged: saving ? null : (v) => setDialogState(() => sexo = v ?? sexo),
                    ),
                    TextField(
                      controller: telCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Telefone'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: saving ? null : () => Navigator.pop(ctx), child: const Text('Cancelar')),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final idade = int.tryParse(idadeCtrl.text.trim());
                          if (nameCtrl.text.trim().isEmpty || idade == null || idade < 13 || telCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Preencha nome, idade (≥13) e telefone.')),
                            );
                            return;
                          }
                          setDialogState(() => saving = true);
                          try {
                            await BolaoApi.patchProfile(
                              fullName: nameCtrl.text.trim(),
                              idade: idade,
                              sexo: sexo,
                              telefone: telCtrl.text.trim(),
                            );
                            if (context.mounted) {
                              Navigator.pop(ctx);
                              _reload();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Perfil salvo.')),
                              );
                            }
                          } on ApiException catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                            }
                          } finally {
                            setDialogState(() => saving = false);
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _DarkLabeledField extends StatelessWidget {
  const _DarkLabeledField({
    required this.label,
    required this.value,
    required this.onEdit,
  });

  final String label;
  final String value;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark ? const Color(0xFF0F172A) : scheme.surfaceContainerHighest;
    final labelColor = isDark ? Colors.white70 : scheme.onSurfaceVariant;
    final valueColor = isDark ? Colors.white : scheme.onSurface;
    final iconColor = isDark ? Colors.white : scheme.primary;

    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: t.labelSmall?.copyWith(
                        color: labelColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: t.bodyLarge?.copyWith(
                        color: valueColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: Icon(Icons.edit_outlined, color: iconColor),
                tooltip: 'Editar',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
