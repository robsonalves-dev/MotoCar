import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EditarViagemPage extends StatefulWidget {
  final int id;
  final String origem;
  final String destino;
  final double distanciaKm;
  final double tempoMinutos;
  final String combustivel;
  final double consumoKmL;
  final double precoCombustivel;
  final double litrosNecessarios;
  final double custoViagem;

  const EditarViagemPage({
    super.key,
    required this.id,
    required this.origem,
    required this.destino,
    required this.distanciaKm,
    required this.tempoMinutos,
    required this.combustivel,
    required this.consumoKmL,
    required this.precoCombustivel,
    required this.litrosNecessarios,
    required this.custoViagem,
  });

  @override
  State<EditarViagemPage> createState() =>
      _EditarViagemPageState();
}

class _EditarViagemPageState
    extends State<EditarViagemPage> {
  late final TextEditingController origemController;
  late final TextEditingController destinoController;
  late final TextEditingController distanciaController;
  late final TextEditingController tempoController;
  late final TextEditingController consumoController;
  late final TextEditingController precoController;
  late final TextEditingController litrosController;
  late final TextEditingController custoController;

  late String combustivel;

  bool salvando = false;
  String mensagem = '';

  static const Color azulMotoCar = Color(0xFF1565C0);
  static const Color fundo = Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();

    origemController =
        TextEditingController(text: widget.origem);

    destinoController =
        TextEditingController(text: widget.destino);

    distanciaController = TextEditingController(
      text: widget.distanciaKm.toString(),
    );

    tempoController = TextEditingController(
      text: widget.tempoMinutos.toString(),
    );

    consumoController = TextEditingController(
      text: widget.consumoKmL.toString(),
    );

    precoController = TextEditingController(
      text: widget.precoCombustivel.toString(),
    );

    litrosController = TextEditingController(
      text: widget.litrosNecessarios.toString(),
    );

    custoController = TextEditingController(
      text: widget.custoViagem.toString(),
    );

    combustivel = widget.combustivel;
  }

  @override
  void dispose() {
    origemController.dispose();
    destinoController.dispose();
    distanciaController.dispose();
    tempoController.dispose();
    consumoController.dispose();
    precoController.dispose();
    litrosController.dispose();
    custoController.dispose();
    super.dispose();
  }

  Future<void> salvarAlteracoes() async {
    setState(() {
      salvando = true;
      mensagem = '';
    });

    try {
      final prefs =
          await SharedPreferences.getInstance();

      final usuarioId =
          prefs.getInt('usuario_id');

      if (usuarioId == null || usuarioId <= 0) {
        if (!mounted) return;

        setState(() {
          salvando = false;
          mensagem =
              'Usuário não identificado. Faça login novamente.';
        });

        return;
      }

      final distancia = double.tryParse(
        distanciaController.text.replaceAll(',', '.'),
      );

      final tempo = double.tryParse(
        tempoController.text.replaceAll(',', '.'),
      );

      final consumo = double.tryParse(
        consumoController.text.replaceAll(',', '.'),
      );

      final preco = double.tryParse(
        precoController.text.replaceAll(',', '.'),
      );

      final litros = double.tryParse(
        litrosController.text.replaceAll(',', '.'),
      );

      final custo = double.tryParse(
        custoController.text.replaceAll(',', '.'),
      );

      if (origemController.text.trim().isEmpty ||
          destinoController.text.trim().isEmpty ||
          distancia == null ||
          tempo == null ||
          consumo == null ||
          preco == null ||
          litros == null ||
          custo == null) {
        setState(() {
          salvando = false;
          mensagem =
              'Preencha todos os campos corretamente.';
        });

        return;
      }

      final response = await http.put(
        Uri.parse(
          'https://motocarweb.com.br/backend/api/viagens.php',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id': widget.id,
          'usuario_id': usuarioId,
          'origem': origemController.text.trim(),
          'destino': destinoController.text.trim(),
          'distancia_km': distancia,
          'tempo_minutos': tempo,
          'combustivel': combustivel.toLowerCase(),
          'consumo_km_l': consumo,
          'preco_combustivel': preco,
          'litros_necessarios': litros,
          'custo_viagem': custo,
        }),
      );

      final dados = jsonDecode(response.body);

      if (!mounted) return;

      if (dados['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Viagem atualizada com sucesso!',
            ),
          ),
        );

        Navigator.pop(context, true);
        return;
      }

      setState(() {
        salvando = false;
        mensagem =
            dados['mensagem'] ??
            'Não foi possível atualizar a viagem.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        salvando = false;
        mensagem =
            'Erro ao conectar com a API.';
      });
    }
  }

  InputDecoration campoDecoracao({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        color: azulMotoCar,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 17,
      ),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFE1E6ED),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: azulMotoCar,
          width: 1.5,
        ),
      ),
    );
  }

  Widget campoSecao({
    required String titulo,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF263238),
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        foregroundColor:
            const Color(0xFF263238),
        centerTitle: true,
        title: const Text(
          'Editar viagem',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: Color(0xFF263238),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          18,
          20,
          18,
          30,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Editar viagem',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF263238),
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Altere os dados da viagem e salve as modificações.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.04,
                    ),
                    blurRadius: 12,
                    offset:
                        const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Percurso',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          Color(0xFF263238),
                    ),
                  ),

                  const SizedBox(height: 18),

                  campoSecao(
                    titulo: 'Origem',
                    child: TextField(
                      controller:
                          origemController,
                      keyboardType:
                          TextInputType.streetAddress,
                      textCapitalization:
                          TextCapitalization.sentences,
                      maxLines: 2,
                      decoration:
                          campoDecoracao(
                        label:
                            'Endereço de origem',
                        icon: Icons
                            .location_on_outlined,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  campoSecao(
                    titulo: 'Destino',
                    child: TextField(
                      controller:
                          destinoController,
                      keyboardType:
                          TextInputType.streetAddress,
                      textCapitalization:
                          TextCapitalization.sentences,
                      maxLines: 2,
                      decoration:
                          campoDecoracao(
                        label:
                            'Endereço de destino',
                        icon:
                            Icons.flag_outlined,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.04,
                    ),
                    blurRadius: 12,
                    offset:
                        const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dados da viagem',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          Color(0xFF263238),
                    ),
                  ),

                  const SizedBox(height: 18),

                  campoSecao(
                    titulo: 'Distância',
                    child: TextField(
                      controller:
                          distanciaController,
                      keyboardType:
                          const TextInputType
                              .numberWithOptions(
                        decimal: true,
                      ),
                      decoration:
                          campoDecoracao(
                        label:
                            'Distância em km',
                        icon:
                            Icons.route,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  campoSecao(
                    titulo: 'Tempo',
                    child: TextField(
                      controller:
                          tempoController,
                      keyboardType:
                          const TextInputType
                              .numberWithOptions(
                        decimal: true,
                      ),
                      decoration:
                          campoDecoracao(
                        label:
                            'Tempo em minutos',
                        icon:
                            Icons.access_time,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  campoSecao(
                    titulo: 'Combustível',
                    child:
                        DropdownButtonFormField<
                            String>(
                      initialValue:
                          combustivel,
                      decoration:
                          campoDecoracao(
                        label:
                            'Tipo de combustível',
                        icon: Icons
                            .local_gas_station_outlined,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Gasolina',
                          child:
                              Text('Gasolina'),
                        ),
                        DropdownMenuItem(
                          value: 'Etanol',
                          child:
                              Text('Etanol'),
                        ),
                      ],
                      onChanged: (valor) {
                        if (valor != null) {
                          setState(() {
                            combustivel =
                                valor;
                          });
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  campoSecao(
                    titulo: 'Consumo',
                    child: TextField(
                      controller:
                          consumoController,
                      keyboardType:
                          const TextInputType
                              .numberWithOptions(
                        decimal: true,
                      ),
                      decoration:
                          campoDecoracao(
                        label:
                            'Consumo em km/l',
                        icon:
                            Icons.speed_outlined,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  campoSecao(
                    titulo:
                        'Preço do combustível',
                    child: TextField(
                      controller:
                          precoController,
                      keyboardType:
                          const TextInputType
                              .numberWithOptions(
                        decimal: true,
                      ),
                      decoration:
                          campoDecoracao(
                        label:
                            'Preço por litro',
                        icon:
                            Icons.payments_outlined,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  campoSecao(
                    titulo:
                        'Litros necessários',
                    child: TextField(
                      controller:
                          litrosController,
                      keyboardType:
                          const TextInputType
                              .numberWithOptions(
                        decimal: true,
                      ),
                      decoration:
                          campoDecoracao(
                        label:
                            'Quantidade de litros',
                        icon:
                            Icons.water_drop_outlined,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  campoSecao(
                    titulo:
                        'Custo da viagem',
                    child: TextField(
                      controller:
                          custoController,
                      keyboardType:
                          const TextInputType
                              .numberWithOptions(
                        decimal: true,
                      ),
                      decoration:
                          campoDecoracao(
                        label:
                            'Custo estimado',
                        icon:
                            Icons.payments_outlined,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: salvando
                    ? null
                    : salvarAlteracoes,
                icon: salvando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.save_outlined,
                        color:
                            Colors.white,
                      ),
                label: Text(
                  salvando
                      ? 'Salvando...'
                      : 'Salvar alterações',
                ),
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      azulMotoCar,
                  foregroundColor:
                      Colors.white,
                  disabledBackgroundColor:
                      azulMotoCar.withValues(
                    alpha: 0.6,
                  ),
                  elevation: 0,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                            15),
                  ),
                  textStyle:
                      const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),

            if (mensagem.isNotEmpty) ...[
              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFFFF4F4),
                  borderRadius:
                      BorderRadius.circular(
                          15),
                  border: Border.all(
                    color: const Color(
                        0xFFFFD6D6),
                  ),
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                    ),
                    const SizedBox(
                        width: 10),
                    Expanded(
                      child: Text(
                        mensagem,
                        style:
                            const TextStyle(
                          color: Color(
                              0xFFB42318),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}