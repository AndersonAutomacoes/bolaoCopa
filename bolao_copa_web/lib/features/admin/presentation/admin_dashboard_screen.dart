import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
        title: const Text('Administração'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Requer ROLE_ADMIN no backend. Operações retornam 403 se não for administrador.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Seleções'),
            subtitle: const Text('Cadastro de times, nomes e bandeiras'),
            onTap: () => context.push(AppRoutes.adminSelecoes),
          ),
          ListTile(
            leading: const Icon(Icons.sports_soccer),
            title: const Text('Jogos'),
            subtitle: const Text('Partidas, datas e resultados oficiais'),
            onTap: () => context.push(AppRoutes.adminJogos),
          ),
        ],
      ),
    );
  }
}
