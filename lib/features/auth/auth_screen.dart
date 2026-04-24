import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/widgets/app_badge.dart';
import '../../core/widgets/glass_card.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isRegisterMode = false;
  String? _message;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      if (_isRegisterMode) {
        final username = _usernameController.text.trim();
        if (username.isEmpty) {
          setState(() => _message = 'Kullanıcı adı gereklidir.');
          return;
        }

        await Supabase.instance.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          data: {'username': username},
        );

        if (mounted) {
          setState(() {
            _message = 'Kayıt başarılı. Hesabın varsa direkt giriş yapabilirsin.';
            _isRegisterMode = false;
          });
        }
        return;
      }

      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on AuthException catch (error) {
      setState(() => _message = error.message);
    } catch (_) {
      setState(() => _message = 'Bir hata oluştu. Lütfen tekrar dene.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleMode(bool registerMode) {
    if (_isLoading || registerMode == _isRegisterMode) {
      return;
    }

    setState(() {
      _isRegisterMode = registerMode;
      _message = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: GlassCard(
                variant: GlassCardVariant.highlighted,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AppBadge(
                        label: 'Mobil PWA parity',
                        icon: Icons.sports_soccer_rounded,
                        tone: AppBadgeTone.primary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Futbol Bilgi', style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(
                      _isRegisterMode ? 'Mobil hesabını oluştur ve hemen oyuna başla.' : 'Hesabına giriş yapıp mobile devam et.',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 20),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment<bool>(value: false, label: Text('Giriş Yap')),
                        ButtonSegment<bool>(value: true, label: Text('Kayıt Ol')),
                      ],
                      selected: {_isRegisterMode},
                      onSelectionChanged: (selection) => _toggleMode(selection.first),
                    ),
                    const SizedBox(height: 20),
                    if (_isRegisterMode) ...[
                      TextField(
                        controller: _usernameController,
                        enabled: !_isLoading,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'Kullanıcı adı'),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: _emailController,
                      enabled: !_isLoading,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'E-posta'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      enabled: !_isLoading,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(labelText: 'Şifre'),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                      child: Text(_isLoading ? 'İşleniyor...' : _isRegisterMode ? 'Kayıt Ol' : 'Giriş Yap'),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isRegisterMode
                          ? 'Kayıttan sonra aynı ekran üzerinden giriş yapabilirsin.'
                          : 'Web hesabınla aynı Supabase oturumunu kullanırsın.',
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 16),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(_message!),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
