import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class CalculosPage extends StatefulWidget {
  const CalculosPage({super.key});

  @override
  State<CalculosPage> createState() => _CalculosPageState();
}

class _CalculosPageState extends State<CalculosPage> {
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;
  static const Color azul = Color(0xFF1976D2);
  static const Color azulEscuro = Color(0xFF1565C0);
  static const Color fundo = Color(0xFFF4F6F9);

  bool carregando = true;
  bool comparando = false;

  String mensagem = '';
  String veiculo = '-';
  String combustivel = '-';

  double? consumoMedio;
  double? custoPorKm;
  double gastoMensal = 0;

  final gasolinaController = TextEditingController();
  final etanolController = TextEditingController();
  final consumoGasolinaController = TextEditingController();
  final consumoEtanolController = TextEditingController();
  final kmMensalController = TextEditingController();

  String resultadoCombustivel = '';

  double? limiteEtanol;
  double? custoKmGasolina;
  double? custoKmEtanol;
  double? gastoMensalEstimadoGasolina;
  double? gastoMensalEstimadoEtanol;

  @override
void initState() {
  super.initState();
  _carregarBanner();
  carregarCalculos();
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

  Future<void> carregarCalculos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioId = prefs.getInt('usuario_id');

      if (usuarioId == null || usuarioId <= 0) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final response = await http.get(
        Uri.parse(
          'https://motocarweb.com.br/backend/api/calculos.php'
          '?usuario_id=$usuarioId',
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Erro HTTP ${response.statusCode}');
      }

      final dados = jsonDecode(response.body);

      if (!mounted) return;

      if (dados['status'] == true) {
        final dadosVeiculo = dados['veiculo'] ?? {};
        final calculos = dados['calculos'] ?? {};

        final marca = dadosVeiculo['marca']?.toString() ?? '';
        final modelo = dadosVeiculo['modelo']?.toString() ?? '';

        veiculo = '$marca $modelo'.trim();

        if (veiculo.isEmpty) {
          veiculo = 'Veículo cadastrado';
        }

        combustivel =
            dadosVeiculo['combustivel']?.toString() ?? '-';

        consumoMedio = double.tryParse(
          calculos['consumo_medio_km_l']?.toString() ?? '',
        );

        custoPorKm = double.tryParse(
          calculos['custo_por_km']?.toString() ?? '',
        );

        gastoMensal =
            double.tryParse(
              calculos['gasto_mensal']?.toString() ?? '',
            ) ??
            0;

        if (consumoMedio != null && consumoMedio! > 0) {
          consumoGasolinaController.text =
              consumoMedio!.toStringAsFixed(2);

          consumoEtanolController.text =
              (consumoMedio! * 0.70).toStringAsFixed(2);
        }

        setState(() {
          carregando = false;
          mensagem = '';
        });
      } else {
        setState(() {
          carregando = false;
          mensagem =
              dados['mensagem'] ?? 'Erro ao carregar cálculos.';
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

  Future<void> compararCombustiveis() async {
    final gasolina = double.tryParse(
      gasolinaController.text.replaceAll(',', '.'),
    );

    final etanol = double.tryParse(
      etanolController.text.replaceAll(',', '.'),
    );

    final consumoGasolina = double.tryParse(
      consumoGasolinaController.text.replaceAll(',', '.'),
    );

    final consumoEtanol = double.tryParse(
      consumoEtanolController.text.replaceAll(',', '.'),
    );

    if (gasolina == null ||
        etanol == null ||
        consumoGasolina == null ||
        consumoEtanol == null ||
        gasolina <= 0 ||
        etanol <= 0 ||
        consumoGasolina <= 0 ||
        consumoEtanol <= 0) {
      setState(() {
        resultadoCombustivel =
            'Informe preços e consumos válidos.';
        limiteEtanol = null;
        custoKmGasolina = null;
        custoKmEtanol = null;
      });

      return;
    }

    setState(() {
      comparando = true;
      resultadoCombustivel = '';
    });

    try {
      final response = await http.post(
        Uri.parse(
          'https://motocarweb.com.br/backend/api/'
          'comparar_combustiveis.php',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'preco_gasolina': gasolina,
          'preco_etanol': etanol,
          'consumo_gasolina': consumoGasolina,
          'consumo_etanol': consumoEtanol,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Erro HTTP ${response.statusCode}');
      }

      final dados = jsonDecode(response.body);

      if (!mounted) return;

      if (dados['status'] == true) {
        final resultado =
            dados['mais_economico']?.toString() ?? '';

        setState(() {
          limiteEtanol = double.tryParse(
            dados['limite_etanol']?.toString() ?? '',
          );

          custoKmGasolina = double.tryParse(
            dados['custo_km_gasolina']?.toString() ?? '',
          );

          custoKmEtanol = double.tryParse(
            dados['custo_km_etanol']?.toString() ?? '',
          );

          if (resultado == 'etanol') {
            resultadoCombustivel =
                'Pelos dados informados, o etanol '
                'tem menor custo por km.';
          } else if (resultado == 'gasolina') {
            resultadoCombustivel =
                'Pelos dados informados, a gasolina '
                'tem menor custo por km.';
          } else {
            resultadoCombustivel =
                'Os dois combustíveis têm o mesmo '
                'custo por km.';
          }

          comparando = false;
        });
      } else {
        setState(() {
          comparando = false;
          resultadoCombustivel =
              dados['mensagem'] ??
              'Erro ao comparar combustíveis.';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        comparando = false;
        resultadoCombustivel =
            'Erro ao conectar com a API.';
      });
    }
  }

  void calcularGastoMensalEstimado() {
    final kmMensal = double.tryParse(
      kmMensalController.text.replaceAll(',', '.'),
    );

    final gasolina = double.tryParse(
      gasolinaController.text.replaceAll(',', '.'),
    );

    final etanol = double.tryParse(
      etanolController.text.replaceAll(',', '.'),
    );

    final consumoGasolina = double.tryParse(
      consumoGasolinaController.text.replaceAll(',', '.'),
    );

    final consumoEtanol = double.tryParse(
      consumoEtanolController.text.replaceAll(',', '.'),
    );

    if (kmMensal == null ||
        kmMensal <= 0 ||
        gasolina == null ||
        gasolina <= 0 ||
        etanol == null ||
        etanol <= 0 ||
        consumoGasolina == null ||
        consumoGasolina <= 0 ||
        consumoEtanol == null ||
        consumoEtanol <= 0) {
      setState(() {
        gastoMensalEstimadoGasolina = null;
        gastoMensalEstimadoEtanol = null;
      });

      return;
    }

    final custoGasolina = gasolina / consumoGasolina;
    final custoEtanol = etanol / consumoEtanol;

    setState(() {
      gastoMensalEstimadoGasolina =
          kmMensal * custoGasolina;

      gastoMensalEstimadoEtanol =
          kmMensal * custoEtanol;
    });
  }

  String formatarNumero(double? valor) {
    if (valor == null) {
      return '-';
    }

    return valor.toStringAsFixed(2).replaceAll('.', ',');
  }

  String formatarMoeda(double? valor) {
    if (valor == null) {
      return 'R\$ 0,00';
    }

    return 'R\$ ${formatarNumero(valor)}';
  }

  
Widget cardIndicador({
  required IconData icone,
  required String titulo,
  required String valor,
  required String descricao,
  Color? iconeCor,
}) {
  final cor = iconeCor ?? azul;

  return Container(
    constraints: const BoxConstraints(minHeight: 185),
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: const Color(0xFFE9EDF3),
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A000000),
          blurRadius: 16,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: cor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icone,
                color: cor,
                size: 27,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                titulo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF687386),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          valor,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF151922),
            fontSize: 25,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          descricao,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF929AA6),
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    ),
  );
}


  Widget campo({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: azul,
        ),
        filled: true,
        fillColor: const Color(0xFFF8F9FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: azul,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF151922),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            size: 30,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Cálculos',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFF151922),
          ),
        ),
        actions: [
          IconButton(
            onPressed: carregando ? null : carregarCalculos,
            icon: const Icon(
              Icons.refresh,
              size: 28,
            ),
          ),
        ],
      ),
      body: carregando
          ? const Center(
              child: CircularProgressIndicator(
                color: azul,
              ),
            )
          : mensagem.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: azul.withOpacity(0.10),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.info_outline,
                            color: azul,
                            size: 38,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          mensagem,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 17,
                            color: Color(0xFF6F7680),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: azul,
                  onRefresh: carregarCalculos,
                  child: ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(30),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              azul,
                              azulEscuro,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius:
                              BorderRadius.circular(28),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x331976D2),
                              blurRadius: 24,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color:
                                    Colors.white.withOpacity(0.16),
                                borderRadius:
                                    BorderRadius.circular(22),
                              ),
                              child: const Icon(
                                Icons.directions_car,
                                color: Colors.white,
                                size: 38,
                              ),
                            ),
                            const SizedBox(width: 22),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'MEU VEÍCULO',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      fontWeight:
                                          FontWeight.w700,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    veiculo,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 27,
                                      fontWeight:
                                          FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    combustivel,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                     const SizedBox(height: 24),

if (_isBannerAdReady && _bannerAd != null)
  Center(
    child: SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    ),
  ),

const SizedBox(height: 24),
                      const Text(
                        'Resumo do veículo',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF151922),
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Seus principais indicadores',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF7D8590),
                        ),
                      ),
                      const SizedBox(height: 20),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final duasColunas =
                              constraints.maxWidth >= 700;

                          
final consumo = cardIndicador(
  icone: Icons.speed,
  titulo: 'Consumo médio',
  valor: consumoMedio != null && consumoMedio! > 0
      ? '${formatarNumero(consumoMedio)} km/l'
      : 'Aguardando dados',
  descricao: consumoMedio != null && consumoMedio! > 0
      ? 'Média de consumo do veículo'
      : 'Informe o consumo ou registre abastecimentos',
);

final custo = cardIndicador(
  icone: Icons.attach_money,
  titulo: 'Custo por km',
  valor: custoPorKm == null
      ? 'Aguardando dados'
      : formatarMoeda(custoPorKm),
  descricao: custoPorKm == null
      ? 'Registre abastecimentos com quilometragem e valor'
      : 'Custo médio de cada quilômetro rodado',
);


                          if (duasColunas) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: consumo),
                                const SizedBox(width: 18),
                                Expanded(child: custo),
                              ],
                            );
                          }

                          return Column(
                            children: [
                              consumo,
                              const SizedBox(height: 18),
                              custo,
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      
cardIndicador(
  icone: Icons.calendar_month,
  iconeCor: const Color(0xFF16A34A),
  titulo: 'Gasto neste mês',
  valor: formatarMoeda(gastoMensal),
  descricao: 'Soma dos abastecimentos registrados neste mês',
),

                      const SizedBox(height: 30),
                      Container(
                        padding: const EdgeInsets.all(26),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x12000000),
                              blurRadius: 18,
                              offset: Offset(0, 6),
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
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color:
                                        azul.withOpacity(0.10),
                                    borderRadius:
                                        BorderRadius.circular(17),
                                  ),
                                  child: const Icon(
                                    Icons.local_gas_station,
                                    color: azul,
                                    size: 29,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Gasolina × Etanol',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight:
                                              FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Compare o custo dos combustíveis',
                                        style: TextStyle(
                                          color:
                                              Color(0xFF7D8590),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 25),
                            campo(
                              controller:
                                  gasolinaController,
                              label:
                                  'Gasolina (R\$/litro)',
                              icon:
                                  Icons.local_gas_station,
                            ),
                            const SizedBox(height: 15),
                            campo(
                              controller:
                                  consumoGasolinaController,
                              label:
                                  'Consumo gasolina (km/l)',
                              icon: Icons.speed,
                            ),
                            const SizedBox(height: 15),
                            campo(
                              controller:
                                  etanolController,
                              label:
                                  'Etanol (R\$/litro)',
                              icon:
                                  Icons.local_gas_station,
                            ),
                            const SizedBox(height: 15),
                            campo(
                              controller:
                                  consumoEtanolController,
                              label:
                                  'Consumo etanol (km/l)',
                              icon: Icons.speed,
                            ),
                            const SizedBox(height: 22),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: comparando
                                    ? null
                                    : compararCombustiveis,
                                style:
                                    ElevatedButton.styleFrom(
                                  backgroundColor: azul,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(16),
                                  ),
                                ),
                                child: comparando
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Comparar combustíveis',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight:
                                              FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                            if (resultadoCombustivel
                                .isNotEmpty) ...[
                              const SizedBox(height: 20),
                              Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color:
                                      azul.withOpacity(0.07),
                                  borderRadius:
                                      BorderRadius.circular(16),
                                ),
                                child: Text(
                                  resultadoCombustivel,
                                  style: const TextStyle(
                                    color: azulEscuro,
                                    fontWeight:
                                        FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                            if (limiteEtanol != null) ...[
                              const SizedBox(height: 18),
                              Text(
                                'Preço limite do etanol: '
                                '${formatarMoeda(limiteEtanol)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                            if (custoKmGasolina != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                'Gasolina: '
                                '${formatarMoeda(custoKmGasolina)} por km',
                              ),
                            ],
                            if (custoKmEtanol != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Etanol: '
                                '${formatarMoeda(custoKmEtanol)} por km',
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.all(26),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x12000000),
                              blurRadius: 18,
                              offset: Offset(0, 6),
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
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color:
                                        const Color(0xFF16A34A)
                                            .withOpacity(0.10),
                                    borderRadius:
                                        BorderRadius.circular(17),
                                  ),
                                  child: const Icon(
                                    Icons.calculate,
                                    color:
                                        Color(0xFF16A34A),
                                    size: 29,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Gasto mensal estimado',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight:
                                              FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Veja quanto você gastaria por mês',
                                        style: TextStyle(
                                          color:
                                              Color(0xFF7D8590),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 25),
                            campo(
                              controller:
                                  kmMensalController,
                              label: 'Quilômetros por mês',
                              icon: Icons.route,
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed:
                                    calcularGastoMensalEstimado,
                                style:
                                    ElevatedButton.styleFrom(
                                  backgroundColor: azul,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'Calcular gasto mensal',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            if (gastoMensalEstimadoGasolina !=
                                    null ||
                                gastoMensalEstimadoEtanol !=
                                    null) ...[
                              const SizedBox(height: 25),
                              Row(
                                children: [
                                  Expanded(
                                    child: _resultadoMensal(
                                      'Gasolina',
                                      gastoMensalEstimadoGasolina,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _resultadoMensal(
                                      'Etanol',
                                      gastoMensalEstimadoEtanol,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }

  Widget _resultadoMensal(
    String titulo,
    double? valor,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: Color(0xFF7D8590),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            formatarMoeda(valor),
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    gasolinaController.dispose();
    etanolController.dispose();
    consumoGasolinaController.dispose();
    consumoEtanolController.dispose();
    kmMensalController.dispose();
    
_bannerAd?.dispose();

    super.dispose();
  }
}