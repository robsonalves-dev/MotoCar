import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends State<ConfiguracoesPage> {
  final _formKey = GlobalKey<FormState>();

  bool carregando = true;
  bool salvandoDados = false;
  bool alterandoSenha = false;

  final TextEditingController nomeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaAtualController =
      TextEditingController();
  final TextEditingController novaSenhaController =
      TextEditingController();
  final TextEditingController confirmarSenhaController =
      TextEditingController();

  bool mostrarSenhaAtual = false;
  bool mostrarNovaSenha = false;
  bool mostrarConfirmacao = false;

  static const String api =
      'https://motocarweb.com.br/backend/api/app/configuracoes_app.php';

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    senhaAtualController.dispose();
    novaSenhaController.dispose();
    confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> carregarDados() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioId = prefs.getInt('usuario_id');

      if (usuarioId == null) {
        if (!mounted) return;

        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final response = await http.get(
        Uri.parse('$api?usuario_id=$usuarioId'),
      );

      if (response.statusCode != 200) {
        throw Exception();
      }

      final dados = jsonDecode(response.body);

      if (dados['sucesso'] == true) {
        final usuario = dados['usuario'];

        nomeController.text = usuario['nome']?.toString() ?? '';
        emailController.text = usuario['email']?.toString() ?? '';

        final nome = usuario['nome']?.toString() ?? '';

        await prefs.setString('usuario_nome', nome);
      } else {
        mostrarMensagem(
          dados['mensagem']?.toString() ??
              'Não foi possível carregar seus dados.',
        );
      }
    } catch (e) {
      mostrarMensagem(
        'Não foi possível carregar os dados da conta.',
      );
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  Future<void> salvarDados() async {
    if (salvandoDados) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final senhaAtual = senhaAtualController.text.trim();

    if (senhaAtual.isEmpty) {
      mostrarMensagem(
        'Digite sua senha atual para salvar as alterações.',
      );
      return;
    }

    setState(() {
      salvandoDados = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioId = prefs.getInt('usuario_id');

      if (usuarioId == null) {
        if (!mounted) return;

        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final response = await http.post(
        Uri.parse(api),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'usuario_id': usuarioId,
          'nome': nomeController.text.trim(),
          'email': emailController.text.trim(),
          'senha_atual': senhaAtual,
          'nova_senha': '',
        }),
      );

      final dados = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          dados['sucesso'] == true) {
        await prefs.setString(
          'usuario_nome',
          nomeController.text.trim(),
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Dados atualizados com sucesso!',
            ),
          ),
        );

        senhaAtualController.clear();
      } else {
        mostrarMensagem(
          dados['mensagem']?.toString() ??
              'Não foi possível atualizar os dados.',
        );
      }
    } catch (e) {
      mostrarMensagem(
        'Não foi possível conectar ao servidor.',
      );
    } finally {
      if (mounted) {
        setState(() {
          salvandoDados = false;
        });
      }
    }
  }

  Future<void> alterarSenha() async {
    if (alterandoSenha) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final senhaAtual = senhaAtualController.text;
    final novaSenha = novaSenhaController.text;
    final confirmarSenha = confirmarSenhaController.text;

    if (senhaAtual.isEmpty) {
      mostrarMensagem(
        'Digite sua senha atual.',
      );
      return;
    }

    if (novaSenha.isEmpty) {
      mostrarMensagem(
        'Digite a nova senha.',
      );
      return;
    }

    if (novaSenha.length < 8) {
      mostrarMensagem(
        'A nova senha deve ter pelo menos 8 caracteres.',
      );
      return;
    }

    if (novaSenha != confirmarSenha) {
      mostrarMensagem(
        'As senhas não coincidem.',
      );
      return;
    }

    setState(() {
      alterandoSenha = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioId = prefs.getInt('usuario_id');

      if (usuarioId == null) {
        if (!mounted) return;

        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final response = await http.post(
        Uri.parse(api),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'usuario_id': usuarioId,
          'nome': nomeController.text.trim(),
          'email': emailController.text.trim(),
          'senha_atual': senhaAtual,
          'nova_senha': novaSenha,
        }),
      );

      final dados = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          dados['sucesso'] == true) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Senha alterada com sucesso!',
            ),
          ),
        );

        senhaAtualController.clear();
        novaSenhaController.clear();
        confirmarSenhaController.clear();
      } else {
        mostrarMensagem(
          dados['mensagem']?.toString() ??
              'Não foi possível alterar a senha.',
        );
      }
    } catch (e) {
      mostrarMensagem(
        'Não foi possível conectar ao servidor.',
      );
    } finally {
      if (mounted) {
        setState(() {
          alterandoSenha = false;
        });
      }
    }
  }

  void mostrarMensagem(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
      ),
    );
  }

  InputDecoration campoDecoracao({
    required String label,
    required IconData icone,
    Widget? sufixo,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icone),
      suffixIcon: sufixo,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Theme.of(context)
              .dividerColor
              .withValues(alpha: 0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1.5,
        ),
      ),
    );
  }

  Widget campoSenha({
    required String label,
    required TextEditingController controller,
    required bool mostrar,
    required VoidCallback alternar,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !mostrar,
      validator: validator,
      decoration: campoDecoracao(
        label: label,
        icone: Icons.lock_outline,
        sufixo: IconButton(
          onPressed: alternar,
          icon: Icon(
            mostrar ? Icons.visibility_off : Icons.visibility,
          ),
        ),
      ),
    );
  }

  Widget secao({
    required String titulo,
    required String descricao,
    required IconData icone,
    required List<Widget> filhos,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Theme.of(context)
              .dividerColor
              .withValues(alpha: 0.25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      Theme.of(context)
                          .colorScheme
                          .primaryContainer,
                  child: Icon(
                    icone,
                    color:
                        Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        descricao,
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            ...filhos,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: carregando
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.manage_accounts_outlined,
                            size: 42,
                            color: Theme.of(context)
                                .colorScheme
                                .primary,
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Minha conta',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Gerencie seus dados e a segurança da sua conta.',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    secao(
                      titulo: 'Dados pessoais',
                      descricao:
                          'Atualize suas informações',
                      icone: Icons.person_outline,
                      filhos: [
                        TextFormField(
                          controller: nomeController,
                          textCapitalization:
                              TextCapitalization.words,
                          decoration: campoDecoracao(
                            label: 'Nome completo',
                            icone:
                                Icons.person_outline,
                          ),
                          validator: (valor) {
                            if (valor == null ||
                                valor.trim().isEmpty) {
                              return 'Informe seu nome';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: emailController,
                          keyboardType:
                              TextInputType.emailAddress,
                          decoration: campoDecoracao(
                            label: 'E-mail',
                            icone:
                                Icons.email_outlined,
                          ),
                          validator: (valor) {
                            if (valor == null ||
                                !RegExp(
                                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                ).hasMatch(
                                  valor.trim(),
                                )) {
                              return 'Informe um e-mail válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 52,
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: salvandoDados
                                ? null
                                : salvarDados,
                            icon: salvandoDados
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.save_outlined,
                                  ),
                            label: const Text(
                              'Salvar dados',
                            ),
                          ),
                        ),
                      ],
                    ),

                    secao(
                      titulo: 'Segurança',
                      descricao:
                          'Altere sua senha de acesso',
                      icone: Icons.shield_outlined,
                      filhos: [
                        campoSenha(
                          label: 'Senha atual',
                          controller:
                              senhaAtualController,
                          mostrar:
                              mostrarSenhaAtual,
                          alternar: () {
                            setState(() {
                              mostrarSenhaAtual =
                                  !mostrarSenhaAtual;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        campoSenha(
                          label: 'Nova senha',
                          controller:
                              novaSenhaController,
                          mostrar:
                              mostrarNovaSenha,
                          alternar: () {
                            setState(() {
                              mostrarNovaSenha =
                                  !mostrarNovaSenha;
                            });
                          },
                          validator: (valor) {
                            if (valor != null &&
                                valor.isNotEmpty &&
                                valor.length < 8) {
                              return 'Use pelo menos 8 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        campoSenha(
                          label: 'Confirmar nova senha',
                          controller:
                              confirmarSenhaController,
                          mostrar:
                              mostrarConfirmacao,
                          alternar: () {
                            setState(() {
                              mostrarConfirmacao =
                                  !mostrarConfirmacao;
                            });
                          },
                          validator: (valor) {
                            if (novaSenhaController
                                    .text
                                    .isNotEmpty &&
                                valor !=
                                    novaSenhaController
                                        .text) {
                              return 'As senhas não coincidem';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 52,
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: alterandoSenha
                                ? null
                                : alterarSenha,
                            icon: alterandoSenha
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.lock_reset,
                                  ),
                            label: const Text(
                              'Alterar senha',
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Center(
                      child: Text(
                        'MotoCar • Configurações da conta',
                        style: TextStyle(
                          color: Theme.of(context)
                              .hintColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}