import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/bolao_api.dart';
import '../../../core/api/error_message.dart';
import '../../../core/models/user_profile_dto.dart';
import '../../../core/formatting/profile_labels.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/app_detail_skeleton.dart';
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
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh), tooltip: 'Atualizar'),
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
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
              const SizedBox(height: 16),
              Text('Dados cadastrais', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _ReadField(label: 'Nome', value: profile.fullName),
              _ReadField(label: 'E-mail', value: profile.email),
              _ReadField(label: 'Idade', value: '${profile.idade}'),
              _ReadField(label: 'Sexo', value: formatSexoDisplay(profile.sexo)),
              _ReadField(label: 'Telefone', value: profile.telefone),
              _ReadField(label: 'Plano', value: formatPlanTierLabel(profile.planTier)),
              _ReadField(label: 'Papel', value: formatRolesLabel(profile.roles)),
              const SizedBox(height: 24),
              if (profile.isAdmin)
                FilledButton.icon(
                  onPressed: () => context.push(AppRoutes.admin),
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  label: const Text('Administração (jogos / seleções)'),
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
              const SizedBox(height: 24),
              FilledButton.tonalIcon(
                onPressed: () => _openEditDialog(context, profile),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar perfil'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Sair'),
              ),
            ],
          );
        },
      ),
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

class _ReadField extends StatelessWidget {
  const _ReadField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
      ),
    );
  }
}
