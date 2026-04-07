import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/auth_page_background.dart';
import '../../../core/widgets/branding_logo.dart';

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
  final _confirmSenha = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _aceitoTermos = false;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _idade.dispose();
    _telefone.dispose();
    _senha.dispose();
    _confirmSenha.dispose();
    super.dispose();
  }

  void _stubTermos(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label — em breve.')),
    );
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _senha.text;
    final confirm = _confirmSenha.text;
    final fullName = _nome.text.trim();
    final telefone = _telefone.text.trim();
    final idadeParsed = int.tryParse(_idade.text.trim());

    if (!_aceitoTermos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aceite os Termos de Uso e a Política de Privacidade.')),
      );
      return;
    }
    if (email.isEmpty || password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('E-mail obrigatório e senha com no mínimo 8 caracteres.')),
      );
      return;
    }
    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('As senhas não coincidem.')),
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
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final labelStyle = t.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
      color: AppTheme.textPrimary,
    );

    InputDecoration fieldDeco({
      required String hintText,
      Widget? prefix,
      Widget? suffix,
    }) {
      return InputDecoration(
        hintText: hintText,
        prefixIcon: prefix,
        suffixIcon: suffix,
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AuthPageBackground(),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: AppLayout.registerCardMaxWidth),
                        child: Card(
                          elevation: 6,
                          shadowColor: Colors.black.withValues(alpha: 0.12),
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: AppLayout.authCardPadding,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const BrandingLogo(height: 44),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Bolão',
                                          style: t.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          'Copa 2026',
                                          style: t.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Onde o Torcedor Vence!',
                                  textAlign: TextAlign.center,
                                  style: t.labelLarge?.copyWith(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  'Crie sua Conta',
                                  textAlign: TextAlign.center,
                                  style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 24),
                                Text('Nome completo', style: labelStyle),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _nome,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: fieldDeco(
                                    hintText: 'Digite seu nome completo',
                                    prefix: Icon(Icons.person_outline, color: scheme.onSurfaceVariant),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text('E-mail', style: labelStyle),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _email,
                                  keyboardType: TextInputType.emailAddress,
                                  autofillHints: const [AutofillHints.email],
                                  decoration: fieldDeco(
                                    hintText: 'Seu endereço de e-mail',
                                    prefix: Icon(Icons.alternate_email, color: scheme.onSurfaceVariant),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text('Senha', style: labelStyle),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _senha,
                                  obscureText: _obscurePassword,
                                  autofillHints: const [AutofillHints.newPassword],
                                  decoration: fieldDeco(
                                    hintText: 'Mínimo de 8 caracteres',
                                    prefix: Icon(Icons.lock_outline, color: scheme.onSurfaceVariant),
                                    suffix: IconButton(
                                      tooltip: _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
                                      onPressed: () =>
                                          setState(() => _obscurePassword = !_obscurePassword),
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text('Confirmar senha', style: labelStyle),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _confirmSenha,
                                  obscureText: _obscureConfirm,
                                  autofillHints: const [AutofillHints.newPassword],
                                  decoration: fieldDeco(
                                    hintText: 'Repita a senha',
                                    prefix: Icon(Icons.lock_outline, color: scheme.onSurfaceVariant),
                                    suffix: IconButton(
                                      tooltip: _obscureConfirm ? 'Mostrar senha' : 'Ocultar senha',
                                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                      icon: Icon(
                                        _obscureConfirm
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Perfil (obrigatório no cadastro)',
                                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _idade,
                                  keyboardType: TextInputType.number,
                                  decoration: fieldDeco(
                                    hintText: 'Idade',
                                    prefix: Icon(Icons.cake_outlined, color: scheme.onSurfaceVariant),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  // ignore: deprecated_member_use
                                  value: _sexo,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: scheme.surface,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    labelText: 'Sexo',
                                  ),
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
                                  decoration: fieldDeco(
                                    hintText: 'Telefone',
                                    prefix: Icon(Icons.phone_outlined, color: scheme.onSurfaceVariant),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Checkbox(
                                      value: _aceitoTermos,
                                      onChanged: _loading
                                          ? null
                                          : (v) => setState(() => _aceitoTermos = v ?? false),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: Text.rich(
                                          TextSpan(
                                            style: t.bodySmall?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                              height: 1.45,
                                            ),
                                            children: [
                                              const TextSpan(text: 'Li e concordo com os '),
                                              TextSpan(
                                                text: 'Termos de Uso',
                                                style: const TextStyle(
                                                  decoration: TextDecoration.underline,
                                                  color: Color(0xFF1D4ED8),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                recognizer: TapGestureRecognizer()
                                                  ..onTap = () => _stubTermos('Termos de Uso'),
                                              ),
                                              const TextSpan(text: ' e '),
                                              TextSpan(
                                                text: 'Política de Privacidade',
                                                style: const TextStyle(
                                                  decoration: TextDecoration.underline,
                                                  color: Color(0xFF1D4ED8),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                recognizer: TapGestureRecognizer()
                                                  ..onTap = () => _stubTermos('Política de Privacidade'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                FilledButton(
                                  onPressed: _loading ? null : _submit,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    foregroundColor: AppTheme.textPrimary,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'CADASTRAR',
                                              style: t.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.6,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(Icons.arrow_forward, size: 20, color: AppTheme.textPrimary),
                                          ],
                                        ),
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      'Já tenho conta? ',
                                      style: t.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                                    ),
                                    TextButton(
                                      onPressed: _loading ? null : () => context.go(AppRoutes.login),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        'Entrar',
                                        style: t.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF38BDF8),
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
