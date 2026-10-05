import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AbastecimentoPage extends StatefulWidget {
  const AbastecimentoPage({super.key});

  @override
  State<AbastecimentoPage> createState() => _AbastecimentoPageState();
}

class _AbastecimentoPageState extends State<AbastecimentoPage> {
  final String apiUrl =
      'https://motocarweb.com.br/backend/api/abastecimentos.php';

  final String listaUrl =
      'https://motocarweb.com.br/backend/api/abastecimentos_lista.php';

  List<dynamic> abastecimentos = [];
List<dynamic> veiculos = [];

BannerAd? _bannerAd;
bool _isBannerAdReady = false;

bool carregando = true;

  @override
void initState() {
  super.initState();
  carregarDados();
  _carregarBanner();
}

void _carregarBanner() {
  _bannerAd = BannerAd(
    adUnitId: 'ca-app-pub-7540081483916932/8634303873',
    size: AdSize.banner,
    request: const AdRequest(),
    listener: BannerAdListener(
      onAdLoaded: (ad) {
        if (!mounted) return;
        setState(() {
          _isBannerAdReady = true;
        });
      },
      onAdFailedToLoad: (ad, error) {
        ad.dispose();
      },
    ),
  )..load();
}

  Future<int?> pegarUsuarioId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('usuario_id');
  }

  // ============================================================
  // CARREGAR ABASTECIMENTOS + VEÍCULOS
  // ============================================================

  Future<void> carregarDados() async {
    setState(() {
      carregando = true;
    });

    try {
      final usuarioId = await pegarUsuarioId();

      if (usuarioId == null) {
        if (!mounted) return;

        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final respostas = await Future.wait([
        http.get(
          Uri.parse('$listaUrl?usuario_id=$usuarioId'),
        ),
        http.get(
          Uri.parse(
            'https://motocarweb.com.br/backend/api/veiculos.php?usuario_id=$usuarioId',
          ),
        ),
      ]);

      final abastecimentosResponse = respostas[0];
      final veiculosResponse = respostas[1];

      if (abastecimentosResponse.statusCode == 200) {
        final dados = jsonDecode(
          abastecimentosResponse.body,
        );

        if (dados['status'] == true) {
          abastecimentos =
              dados['abastecimentos'] ?? [];
        }
      }

      if (veiculosResponse.statusCode == 200) {
        final dados = jsonDecode(
          veiculosResponse.body,
        );

        if (dados['status'] == true) {
          veiculos = dados['veiculos'] ?? [];
        }
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Erro ao carregar os dados.',
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {
        carregando = false;
      });
    }
  }

  // ============================================================
  // SALVAR / EDITAR
  // ============================================================

  Future<void> salvarAbastecimento({
    dynamic id,
    required int veiculoId,
    required String combustivel,
    required String litros,
    required String valor,
    required String quilometragem,
    required DateTime data,
    required bool editando,
  }) async {
    try {
      final usuarioId = await pegarUsuarioId();

      if (usuarioId == null) {
        return;
      }

      final dataFormatada =
          '${data.year}-'
          '${data.month.toString().padLeft(2, '0')}-'
          '${data.day.toString().padLeft(2, '0')}';

      final dados = {
        'usuario_id': usuarioId,
        'veiculo_id': veiculoId,
        'combustivel': combustivel,
        'litros': double.tryParse(
          litros.replaceAll(',', '.'),
        ),
        'valor_total': double.tryParse(
          valor.replaceAll(',', '.'),
        ),
        'quilometragem': double.tryParse(
          quilometragem.replaceAll(',', '.'),
        ),
        'data_abastecimento': dataFormatada,
      };

      http.Response response;

      if (editando) {
        dados['id'] = id;

        response = await http.put(
          Uri.parse(apiUrl),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(dados),
        );
      } else {
        response = await http.post(
          Uri.parse(apiUrl),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(dados),
        );
      }

      final resposta = jsonDecode(
        response.body,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resposta['mensagem'] ??
                'Operação realizada.',
          ),
        ),
      );

      if (resposta['status'] == true) {
        carregarDados();
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Erro ao conectar com o servidor.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // EXCLUIR
  // ============================================================

  Future<void> excluirAbastecimento(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Excluir abastecimento',
          ),
          content: const Text(
            'Tem certeza que deseja excluir este abastecimento?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    try {
      final usuarioId = await pegarUsuarioId();

      if (usuarioId == null) {
        return;
      }

      final response = await http.delete(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id': id,
          'usuario_id': usuarioId,
        }),
      );

      final dados = jsonDecode(
        response.body,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            dados['mensagem'] ??
                'Operação realizada.',
          ),
        ),
      );

      if (dados['status'] == true) {
        carregarDados();
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Erro ao excluir abastecimento.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // FORMULÁRIO
  // ============================================================

  void abrirFormulario({
    Map<String, dynamic>? abastecimento,
  }) {
    final litrosController = TextEditingController(
      text: abastecimento?['litros']?.toString() ?? '',
    );

    final valorController = TextEditingController(
      text:
          abastecimento?['valor_total']?.toString() ?? '',
    );

    final quilometragemController = TextEditingController(
      text:
          abastecimento?['quilometragem']?.toString() ?? '',
    );

    String combustivel =
        abastecimento?['combustivel']?.toString() ??
            'gasolina';

    int? veiculoSelecionado;

    if (abastecimento != null) {
      veiculoSelecionado = int.tryParse(
        abastecimento['veiculo_id'].toString(),
      );
    } else if (veiculos.isNotEmpty) {
      veiculoSelecionado = int.tryParse(
        veiculos.first['id'].toString(),
      );
    }

    DateTime dataAbastecimento =
        DateTime.tryParse(
          abastecimento?['data_abastecimento']
                  ?.toString() ??
              '',
        ) ??
        DateTime.now();

    final bool editando =
        abastecimento != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height:
                  MediaQuery.of(context).size.height *
                      0.90,
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom:
                    MediaQuery.of(context)
                            .viewInsets
                            .bottom +
                        24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 45,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    Text(
                      editando
                          ? 'Editar abastecimento'
                          : 'Adicionar abastecimento',
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 25),

                    // VEÍCULO
                    DropdownButtonFormField<int>(
                      initialValue:
                          veiculoSelecionado,
                      decoration:
                          const InputDecoration(
                        labelText: 'Veículo',
                        border:
                            OutlineInputBorder(),
                      ),
                      items: veiculos.map<
                          DropdownMenuItem<int>>(
                        (veiculo) {
                          final id =
                              int.parse(
                            veiculo['id'].toString(),
                          );

                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text(
                              '${veiculo['marca']} ${veiculo['modelo']}',
                            ),
                          );
                        },
                      ).toList(),
                      onChanged: (valor) {
                        setModalState(() {
                          veiculoSelecionado =
                              valor;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // COMBUSTÍVEL
                    DropdownButtonFormField<String>(
                      initialValue: combustivel,
                      decoration:
                          const InputDecoration(
                        labelText: 'Combustível',
                        border:
                            OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'gasolina',
                          child:
                              Text('Gasolina'),
                        ),
                        DropdownMenuItem(
                          value: 'etanol',
                          child:
                              Text('Etanol'),
                        ),
                      ],
                      onChanged: (valor) {
                        if (valor == null) {
                          return;
                        }

                        setModalState(() {
                          combustivel = valor;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller:
                          litrosController,
                      keyboardType:
                          const TextInputType
                              .numberWithOptions(
                        decimal: true,
                      ),
                      decoration:
                          const InputDecoration(
                        labelText: 'Litros',
                        border:
                            OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller:
                          valorController,
                      keyboardType:
                          const TextInputType
                              .numberWithOptions(
                        decimal: true,
                      ),
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Valor pago (R\$)',
                        border:
                            OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller:
                          quilometragemController,
                      keyboardType:
                          const TextInputType
                              .numberWithOptions(
                        decimal: true,
                      ),
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Quilometragem atual',
                        helperText:
                            'Número que aparece no hodômetro.',
                        border:
                            OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    ListTile(
                      contentPadding:
                          EdgeInsets.zero,
                      title: const Text(
                        'Data do abastecimento',
                      ),
                      subtitle: Text(
                        '${dataAbastecimento.day.toString().padLeft(2, '0')}/'
                        '${dataAbastecimento.month.toString().padLeft(2, '0')}/'
                        '${dataAbastecimento.year}',
                      ),
                      trailing: const Icon(
                        Icons.calendar_month,
                      ),
                      onTap: () async {
                        final data =
                            await showDatePicker(
                          context: context,
                          initialDate:
                              dataAbastecimento,
                          firstDate:
                              DateTime(2020),
                          lastDate:
                              DateTime.now(),
                        );

                        if (data != null) {
                          setModalState(() {
                            dataAbastecimento =
                                data;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed:
                            veiculoSelecionado ==
                                    null
                                ? null
                                : () async {
                                    await salvarAbastecimento(
                                      id: abastecimento?[
                                          'id'],
                                      veiculoId:
                                          veiculoSelecionado!,
                                      combustivel:
                                          combustivel,
                                      litros:
                                          litrosController
                                              .text,
                                      valor:
                                          valorController
                                              .text,
                                      quilometragem:
                                          quilometragemController
                                              .text,
                                      data:
                                          dataAbastecimento,
                                      editando:
                                          editando,
                                    );

                                    if (context
                                        .mounted) {
                                      Navigator.pop(
                                        context,
                                      );
                                    }
                                  },
                        child: Text(
                          editando
                              ? 'Salvar alterações'
                              : 'Adicionar abastecimento',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget cardAbastecimento(
    Map<String, dynamic> abastecimento,
  ) {
    final id = int.tryParse(
      abastecimento['id'].toString(),
    );

    final combustivel =
        abastecimento['combustivel']
                ?.toString() ??
            '-';

    final litros = double.tryParse(
      abastecimento['litros']?.toString() ?? '',
    );

final litrosFormatados = litros == null
    ? '-'
    : litros.toStringAsFixed(3).replaceAll(
        RegExp(r'0+$'),
        '',
      ).replaceAll(
        RegExp(r'\.$'),
        '',
      ).replaceAll('.', ',');

    final valor =
        abastecimento['valor_total']
                ?.toString() ??
            '-';

    final km =
        abastecimento['quilometragem']
                ?.toString() ??
            '-';

    final data =
        abastecimento['data_abastecimento']
                ?.toString() ??
            '-';

    final veiculoId =
        abastecimento['veiculo_id']
            ?.toString();

    String nomeVeiculo = 'Veículo';

    for (final veiculo in veiculos) {
      if (veiculo['id'].toString() ==
          veiculoId) {
        nomeVeiculo =
            '${veiculo['marca']} ${veiculo['modelo']}';
        break;
      }
    }

    return Container(
      margin:
          const EdgeInsets.only(bottom: 15),
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset:
                const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFEAF7EE),
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.local_gas_station,
                  color: Colors.green,
                  size: 28,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      nomeVeiculo,
                      style:
                          const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      combustivel,
                      style:
                          const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              PopupMenuButton<String>(
                onSelected: (valorMenu) {
                  if (valorMenu == 'editar') {
                    abrirFormulario(
                      abastecimento:
                          abastecimento,
                    );
                  }

                  if (valorMenu == 'excluir' &&
                      id != null) {
                    excluirAbastecimento(
                      id,
                    );
                  }
                },
                itemBuilder:
                    (context) => const [
                  PopupMenuItem(
                    value: 'editar',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 10),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'excluir',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        SizedBox(width: 10),
                        Text('Excluir'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          const Divider(),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: Text(
  '$litrosFormatados litros',
  style: const TextStyle(
    fontWeight: FontWeight.bold,
  ),
),
              ),

              Text(
                'R\$ $valor',
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                  color:
                      Color(0xFF1565C0),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(
                Icons.speed,
                size: 16,
                color: Colors.grey,
              ),

              const SizedBox(width: 6),

              Text(
                '$km km',
                style:
                    const TextStyle(
                  color: Colors.grey,
                ),
              ),

              const Spacer(),

              const Icon(
                Icons.calendar_today,
                size: 15,
                color: Colors.grey,
              ),

              const SizedBox(width: 6),

              Text(
                data,
                style:
                    const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TELA
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text(
          'Abastecimentos',
        ),
        centerTitle: true,
        backgroundColor:
            Colors.white,
        foregroundColor:
            Colors.black,
        elevation: 0,
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: veiculos.isEmpty
            ? null
            : () {
                abrirFormulario();
              },
        backgroundColor:
            const Color(0xFF1565C0),
        foregroundColor:
            Colors.white,
        icon: const Icon(
          Icons.add,
        ),
        label: const Text(
          'Adicionar abastecimento',
        ),
      ),

      body: Column(
  children: [
    // BANNER ADMOB NO TOPO
    if (_isBannerAdReady && _bannerAd != null)
      SafeArea(
        child: Center(
          child: SizedBox(
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          ),
        ),
      ),

    // CONTEÚDO DA TELA
    Expanded(
      child: RefreshIndicator(
        onRefresh: carregarDados,
        child: carregando
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : veiculos.isEmpty
                ? ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: const [
                      SizedBox(height: 100),
                      Icon(
                        Icons.directions_car_outlined,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 20),
                      Center(
                        child: Text(
                          'Cadastre um veículo primeiro',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Para registrar um abastecimento, você precisa ter pelo menos um veículo cadastrado.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  )
                : abastecimentos.isEmpty
                    ? ListView(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        children: const [
                          SizedBox(height: 100),
                          Icon(
                            Icons.local_gas_station_outlined,
                            size: 80,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 20),
                          Center(
                            child: Text(
                              'Nenhum abastecimento',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Center(
                            child: Text(
                              'Clique em "Adicionar abastecimento" para registrar o primeiro.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(18),
                        itemCount: abastecimentos.length,
                        itemBuilder: (context, index) {
                          return cardAbastecimento(
                            Map<String, dynamic>.from(
                              abastecimentos[index],
                            ),
                          );
                        },
                      ),
      ),
    ),
  ],
),
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }
}