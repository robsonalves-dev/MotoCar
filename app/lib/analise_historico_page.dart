import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AnaliseHistoricoPage extends StatefulWidget {
  const AnaliseHistoricoPage({super.key});

  @override
  State<AnaliseHistoricoPage> createState() => _AnaliseHistoricoPageState();
}

class _AnaliseHistoricoPageState extends State<AnaliseHistoricoPage> {
  List<dynamic> abastecimentos = [];

  bool carregando = true;
  String mensagem = '';

  String periodoSelecionado = 'Todos';

  double totalGasto = 0;
  double totalLitros = 0;
  double consumoMedio = 0;
  double custoMedioKm = 0;

  static const Color azulMotoCar = Color(0xFF1565C0);
  static const Color fundo = Color(0xFFF5F7FA);

  final String apiUrl =
      'https://motocarweb.com.br/backend/api/abastecimentos_lista.php';

  @override
  void initState() {
    super.initState();
    carregarHistorico();
  }

  Future<void> carregarHistorico() async {
    setState(() {
      carregando = true;
      mensagem = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioId = prefs.getInt('usuario_id');

      if (usuarioId == null || usuarioId <= 0) {
        if (!mounted) return;

        setState(() {
          carregando = false;
          mensagem = 'Usuário não identificado. Faça login novamente.';
        });

        return;
      }

      final response = await http.get(
        Uri.parse('$apiUrl?usuario_id=$usuarioId'),
      );

      if (response.statusCode != 200) {
        throw Exception('Erro HTTP');
      }

      final dados = jsonDecode(response.body);

      if (!mounted) return;

      if (dados['status'] == true) {
        abastecimentos = List<dynamic>.from(
          dados['abastecimentos'] ?? [],
        );

        calcularResumo();

        setState(() {
          carregando = false;

          if (abastecimentos.isEmpty) {
            mensagem = 'Nenhum abastecimento encontrado.';
          }
        });
      } else {
        setState(() {
          carregando = false;
          mensagem =
              dados['mensagem'] ?? 'Não foi possível carregar o histórico.';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        carregando = false;
        mensagem = 'Erro ao conectar com a API.';
      });
    }
  }

  List<dynamic> get abastecimentosFiltrados {
    if (periodoSelecionado == 'Todos') {
      return abastecimentos;
    }

    final agora = DateTime.now();

    int meses;

    switch (periodoSelecionado) {
      case '3 meses':
        meses = 3;
        break;

      case '6 meses':
        meses = 6;
        break;

      case '12 meses':
        meses = 12;
        break;

      default:
        return abastecimentos;
    }

    final dataInicial = DateTime(
      agora.year,
      agora.month - meses,
      agora.day,
    );

    return abastecimentos.where((item) {
      final data = DateTime.tryParse(
        item['data_abastecimento'].toString(),
      );

      if (data == null) {
        return false;
      }

      return data.isAfter(dataInicial) ||
          data.isAtSameMomentAs(dataInicial);
    }).toList();
  }

  void calcularResumo() {
    final lista = abastecimentosFiltrados;

    double gasto = 0;
    double litros = 0;
    double distanciaTotal = 0;

    for (int i = 0; i < lista.length; i++) {
      final atual = lista[i];

      final valor = double.tryParse(
            atual['valor_total'].toString().replaceAll(',', '.'),
          ) ??
          0;

      final litrosAtual = double.tryParse(
            atual['litros'].toString().replaceAll(',', '.'),
          ) ??
          0;

      gasto += valor;
      litros += litrosAtual;

      if (i < lista.length - 1) {
        final kmAtual = double.tryParse(
              atual['quilometragem'].toString().replaceAll(',', '.'),
            ) ??
            0;

        final kmAnterior = double.tryParse(
              lista[i + 1]['quilometragem'].toString().replaceAll(',', '.'),
            ) ??
            0;

        final distancia = kmAtual - kmAnterior;

        if (distancia > 0) {
          distanciaTotal += distancia;
        }
      }
    }

    double consumo = 0;

    if (litros > 0 && distanciaTotal > 0) {
      consumo = distanciaTotal / litros;
    }

    double custoKm = 0;

    if (distanciaTotal > 0) {
      custoKm = gasto / distanciaTotal;
    }

    if (!mounted) return;

    setState(() {
      totalGasto = gasto;
      totalLitros = litros;
      consumoMedio = consumo;
      custoMedioKm = custoKm;
    });
  }

  String formatarNumero(
    double valor, {
    int casas = 2,
  }) {
    return valor.toStringAsFixed(casas).replaceAll('.', ',');
  }

  String formatarData(dynamic valor) {
    final data = DateTime.tryParse(
      valor.toString(),
    );

    if (data == null) {
      return '-';
    }

    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }

  Widget criarResumoCard({
    required IconData icone,
    required String titulo,
    required String valor,
    required String descricao,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icone,
              color: azulMotoCar,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF263238),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  descricao,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget criarAbastecimentoCard(dynamic item) {
    final valor = double.tryParse(
          item['valor_total'].toString().replaceAll(',', '.'),
        ) ??
        0;

    final litros = double.tryParse(
          item['litros'].toString().replaceAll(',', '.'),
        ) ??
        0;

    final km = double.tryParse(
          item['quilometragem'].toString().replaceAll(',', '.'),
        ) ??
        0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_gas_station_outlined,
                  color: azulMotoCar,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item['combustivel']?.toString() ?? 'Combustível',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF263238),
                  ),
                ),
              ),
              Text(
                formatarData(item['data_abastecimento']),
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Wrap(
            spacing: 20,
            runSpacing: 10,
            children: [
              Text(
                'Litros: ${formatarNumero(litros)} L',
                style: const TextStyle(
                  color: Color(0xFF4B5563),
                ),
              ),
              Text(
                'Valor: R\$ ${formatarNumero(valor)}',
                style: const TextStyle(
                  color: Color(0xFF4B5563),
                ),
              ),
              Text(
                'KM: ${formatarNumero(km)}',
                style: const TextStyle(
                  color: Color(0xFF4B5563),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lista = abastecimentosFiltrados;

    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        foregroundColor: const Color(0xFF263238),
        centerTitle: true,
        title: const Text(
          'Análise do histórico',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: Color(0xFF263238),
          ),
        ),
        actions: [
          IconButton(
            onPressed: carregarHistorico,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: carregando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: carregarHistorico,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  18,
                  20,
                  18,
                  30,
                ),
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: periodoSelecionado,
                    decoration: InputDecoration(
                      labelText: 'Período',
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(
                        Icons.calendar_month_outlined,
                        color: azulMotoCar,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFFE1E6ED),
                        ),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Todos',
                        child: Text('Todos'),
                      ),
                      DropdownMenuItem(
                        value: '3 meses',
                        child: Text('Últimos 3 meses'),
                      ),
                      DropdownMenuItem(
                        value: '6 meses',
                        child: Text('Últimos 6 meses'),
                      ),
                      DropdownMenuItem(
                        value: '12 meses',
                        child: Text('Últimos 12 meses'),
                      ),
                    ],
                    onChanged: (valor) {
                      if (valor == null) return;

                      setState(() {
                        periodoSelecionado = valor;
                      });

                      calcularResumo();
                    },
                  ),
                  const SizedBox(height: 20),
                  criarResumoCard(
                    icone: Icons.payments_outlined,
                    titulo: 'Total gasto',
                    valor: 'R\$ ${formatarNumero(totalGasto)}',
                    descricao: 'Total gasto com combustível',
                  ),
                  criarResumoCard(
                    icone: Icons.local_gas_station_outlined,
                    titulo: 'Total abastecido',
                    valor: '${formatarNumero(totalLitros)} L',
                    descricao: 'Litros abastecidos no período',
                  ),
                  criarResumoCard(
                    icone: Icons.speed_outlined,
                    titulo: 'Consumo médio',
                    valor: consumoMedio > 0
                        ? '${formatarNumero(consumoMedio)} km/l'
                        : '-',
                    descricao: 'Média calculada pelo histórico',
                  ),
                  criarResumoCard(
                    icone: Icons.route_outlined,
                    titulo: 'Custo médio por km',
                    valor: custoMedioKm > 0
                        ? 'R\$ ${formatarNumero(custoMedioKm)}'
                        : '-',
                    descricao: 'Custo estimado de combustível por km',
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Abastecimentos do período',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF263238),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (lista.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(30),
                      child: Text(
                        mensagem.isEmpty
                            ? 'Nenhum abastecimento encontrado no período.'
                            : mensagem,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    )
                  else
                    ...lista.map(
                      criarAbastecimentoCard,
                    ),
                ],
              ),
            ),
    );
  }
}