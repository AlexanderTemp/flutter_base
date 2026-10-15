import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../workspace/presentation/workspace_widgets.dart';
import '../application/auth_cubit.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await context.read<AuthCubit>().signIn(_email.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Align(
              alignment: Alignment.centerLeft,
              child: WorkspaceIconButton(
                  label: 'Cerrar inicio de sesión',
                  icon: Icons.close,
                  onTap: () => Navigator.of(context).pop())),
          Expanded(
              child: Center(
                  child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: BlocConsumer<AuthCubit, AuthState>(
                listenWhen: (previous, current) =>
                    previous.user == null && current.user != null,
                listener: (context, _) {
                  if (ModalRoute.of(context)?.isCurrent == true) {
                    Navigator.of(context).pop();
                  }
                },
                builder: (context, state) => ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(28),
                        children: [
                          Icon(Icons.lock_outline,
                              size: 40, color: theme.textColorScheme.action),
                          const SizedBox(height: 24),
                          Text('Tu espacio empieza aquí',
                              style: theme.textStyle.heading3.enhanced(
                                  color: theme.textColorScheme.primary)),
                          const SizedBox(height: 12),
                          Text(
                              'Inicio de sesión de demostración. No conecta con un servidor y no verifica tu identidad. Usa datos ficticios.',
                              style: theme.textStyle.body.standard(
                                  color: theme.textColorScheme.secondary)),
                          const SizedBox(height: 28),
                          Semantics(
                              label: 'Correo electrónico',
                              child: AFTextField(
                                  key: const ValueKey('sign-in-email'),
                                  controller: _email,
                                  hintText: 'tu@ejemplo.com',
                                  keyboardType: TextInputType.emailAddress,
                                  readOnly: state.busy)),
                          const SizedBox(height: 16),
                          Semantics(
                              label: 'Contraseña de demostración',
                              child: AFTextField(
                                  key: const ValueKey('sign-in-password'),
                                  controller: _password,
                                  hintText: 'Contraseña ficticia',
                                  obscureText: true,
                                  readOnly: state.busy,
                                  onSubmitted: (_) => _submit())),
                          if (state.error != null)
                            Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Semantics(
                                    liveRegion: true,
                                    child: Text(state.error!,
                                        style: theme.textStyle.body.standard(
                                            color:
                                                theme.textColorScheme.error)))),
                          const SizedBox(height: 24),
                          Semantics(
                              button: true,
                              container: true,
                              child: AFFilledTextButton.primary(
                                  key: const ValueKey('sign-in-submit'),
                                  text: state.busy
                                      ? 'Conectando…'
                                      : 'Entrar en modo demo',
                                  disabled: state.busy,
                                  onTap: _submit)),
                          const SizedBox(height: 16),
                          Text(
                              'Puedes cerrar esta vista y seguir usando la aplicación como invitado.',
                              style: theme.textStyle.caption.standard(
                                  color: theme.textColorScheme.secondary)),
                        ])),
          ))),
        ]),
      ),
    );
  }
}
