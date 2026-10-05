import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class VeiculoPage extends StatefulWidget {
  const VeiculoPage({super.key});

  @override
  State<VeiculoPage> createState() => _VeiculoPageState();
}

class _VeiculoPageState extends State<VeiculoPage> {
  final String apiUrl =
      'https://motocarweb.com.br/backend/api/veiculos.php';

  List<dynamic> veiculos = [];
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  bool carregando = true;

  @override
void initState() {
  super.initState();
  carregarVeiculos();
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
  // LISTAR VEÍCULOS
  // ============================================================

  Future<void> carregarVeiculos() async {
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

      final response = await http.get(
        Uri.parse('$apiUrl?usuario_id=$usuarioId'),
      );

      if (response.statusCode == 200) {
        final dados = jsonDecode(response.body);

        if (dados['status'] == true) {
          setState(() {
            veiculos = dados['veiculos'] ?? [];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao carregar veículos.'),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        carregando = false;
      });
    }
  }

  // ============================================================
  // EXCLUIR VEÍCULO
  // ============================================================

  Future<void> excluirVeiculo(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir veículo'),
          content: const Text(
            'Tem certeza que deseja excluir este veículo?',
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

      final dados = jsonDecode(response.body);

      if (dados['status'] == true) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veículo excluído com sucesso!'),
          ),
        );

        carregarVeiculos();
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              dados['mensagem'] ?? 'Erro ao excluir veículo.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao conectar com o servidor.'),
        ),
      );
    }
  }

  // ============================================================
  // FORMULÁRIO
  // ============================================================

  void abrirFormulario({
    Map<String, dynamic>? veiculo,
  }) {
    final marcaController = TextEditingController(
      text: veiculo?['marca']?.toString() ?? '',
    );

    final modeloController = TextEditingController(
      text: veiculo?['modelo']?.toString() ?? '',
    );

    final anoController = TextEditingController(
      text: veiculo?['ano']?.toString() ?? '',
    );

    final consumoController = TextEditingController(
      text: veiculo?['consumo_medio']?.toString() ?? '',
    );

    String tipo = veiculo?['tipo']?.toString() ?? 'carro';

    String combustivel =
        veiculo?['combustivel']?.toString() ?? 'flex';

    final bool editando = veiculo != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.90,
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 45,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    Text(
                      editando
                          ? 'Editar veículo'
                          : 'Adicionar veículo',
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 25),

                    DropdownButtonFormField<String>(
                      initialValue: tipo,
                      decoration: const InputDecoration(
                        labelText: 'Tipo',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'carro',
                          child: Text('Carro'),
                        ),
                        DropdownMenuItem(
                          value: 'moto',
                          child: Text('Moto'),
                        ),
                      ],
                      onChanged: (valor) {
                        if (valor == null) return;

                        setModalState(() {
                          tipo = valor;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: marcaController,
                      decoration: const InputDecoration(
                        labelText: 'Marca',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: modeloController,
                      decoration: const InputDecoration(
                        labelText: 'Modelo',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: anoController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Ano',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: combustivel,
                      decoration: const InputDecoration(
                        labelText: 'Combustível',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'flex',
                          child: Text('Flex'),
                        ),
                        DropdownMenuItem(
                          value: 'gasolina',
                          child: Text('Gasolina'),
                        ),
                        DropdownMenuItem(
                          value: 'etanol',
                          child: Text('Etanol'),
                        ),
                      ],
                      onChanged: (valor) {
                        if (valor == null) return;

                        setModalState(() {
                          combustivel = valor;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: consumoController,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Consumo médio (km/l)',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () async {
                          await salvarVeiculo(
                            id: veiculo?['id'],
                            tipo: tipo,
                            marca: marcaController.text,
                            modelo: modeloController.text,
                            ano: anoController.text,
                            combustivel: combustivel,
                            consumo: consumoController.text,
                            editando: editando,
                          );

                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                        child: Text(
                          editando
                              ? 'Salvar alterações'
                              : 'Adicionar veículo',
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
  // SALVAR / EDITAR
  // ============================================================

  Future<void> salvarVeiculo({
    dynamic id,
    required String tipo,
    required String marca,
    required String modelo,
    required String ano,
    required String combustivel,
    required String consumo,
    required bool editando,
  }) async {
    try {
      final usuarioId = await pegarUsuarioId();

      if (usuarioId == null) {
        return;
      }

      final dados = {
        'usuario_id': usuarioId,
        'tipo': tipo,
        'marca': marca.trim(),
        'modelo': modelo.trim(),
        'ano': ano.isEmpty ? null : int.tryParse(ano),
        'combustivel': combustivel,
        'consumo_medio': consumo.isEmpty
            ? null
            : double.tryParse(
                consumo.replaceAll(',', '.'),
              ),
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

      final resposta = jsonDecode(response.body);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resposta['mensagem'] ??
                (editando
                    ? 'Veículo atualizado.'
                    : 'Veículo cadastrado.'),
          ),
        ),
      );

      if (resposta['status'] == true) {
        carregarVeiculos();
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao conectar com o servidor.'),
        ),
      );
    }
  }

  // ============================================================
  // CARD DO VEÍCULO
  // ============================================================

  Widget cardVeiculo(Map<String, dynamic> veiculo) {
    final id = int.tryParse(
      veiculo['id'].toString(),
    );

    final marca = veiculo['marca']?.toString() ?? '';

    final modelo = veiculo['modelo']?.toString() ?? '';

    final ano = veiculo['ano']?.toString() ?? '';

    final tipo = veiculo['tipo']?.toString() ?? '';

    final combustivel =
        veiculo['combustivel']?.toString() ?? '';

    final consumo =
        veiculo['consumo_medio']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  tipo == 'moto'
                      ? Icons.two_wheeler
                      : Icons.directions_car,
                  color: const Color(0xFF1565C0),
                  size: 30,
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$marca $modelo',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      ano.isEmpty
                          ? 'Ano não informado'
                          : 'Ano: $ano',
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              PopupMenuButton<String>(
                onSelected: (valor) {
                  if (valor == 'editar') {
                    abrirFormulario(
                      veiculo: veiculo,
                    );
                  }

                  if (valor == 'excluir' && id != null) {
                    excluirVeiculo(id);
                  }
                },
                itemBuilder: (context) => const [
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

          const SizedBox(height: 15),

          const Divider(),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: Text(
                  'Combustível: $combustivel',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ),

              Text(
                '$consumo km/l',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
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
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text('Meus veículos'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          abrirFormulario();
        },
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Adicionar veículo'),
      ),

      
      body: Column(
  children: [
    if (_isBannerAdReady && _bannerAd != null)
      SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),

    Expanded(
      child: RefreshIndicator(
        onRefresh: carregarVeiculos,
        child: carregando
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : veiculos.isEmpty
                ? ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 100),

                      Icon(
                        Icons.directions_car_outlined,
                        size: 80,
                        color: Colors.grey,
                      ),

                      const SizedBox(height: 20),

                      const Center(
                        child: Text(
                          'Nenhum veículo cadastrado',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Center(
                        child: Text(
                          'Clique em "Adicionar veículo" para cadastrar seu primeiro veículo.',
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
                    itemCount: veiculos.length,
                    itemBuilder: (context, index) {
                      return cardVeiculo(
                        Map<String, dynamic>.from(
                          veiculos[index],
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