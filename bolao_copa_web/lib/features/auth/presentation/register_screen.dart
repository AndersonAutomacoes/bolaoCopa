import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/router/app_router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _idade = TextEditingController();
  String _sexo = 'PREFIRO_NAO_INFORMAR';
  final _telefone = TextEditingController();
  final _senha = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _idade.dispose();
    _telefone.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _senha.text;
    final fullName = _nome.text.trim();
    final telefone = _telefone.text.trim();
    final idadeParsed = int.tryParse(_idade.text.trim());

    if (email.isEmpty || password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('E-mail obrigatório e senha com no mínimo 8 caracteres.')),
      );
      return;
    }
    if (fullName.isEmpty || idadeParsed == null || idadeParsed < 13 || telefone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha nome, idade (≥13) e telefone.')),
      );
      return;
    }

    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loading = true);
    try {
      await AppRouter.auth.registerAndSetupProfile(
        email: email,
        password: password,
        fullName: fullName,
        idade: idadeParsed,
        sexo: _sexo,
        telefone: telefone,
      );
      if (!context.mounted) return;
      router.go(AppRoutes.inicio);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Não foi possível conectar à API: $e')),
      );
    } finally {
      if (context.mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Conta e perfil',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              Text('Seus dados', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              TextField(
                controller: _nome,
                decoration: const InputDecoration(labelText: 'Nome completo'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _idade,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Idade'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _sexo,
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
                onChanged: _loading ? null : (v) => setState(() => _sexo = v ?? _sexo),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _telefone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Telefone'),
              ),
              const SizedBox(height: 20),
              Text('Acesso', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-mail'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _senha,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Senha (mín. 8)'),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Cadastrar'),
              ),
              TextButton(
                onPressed: _loading ? null : () => context.pop(),
                child: const Text('Já tenho conta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
