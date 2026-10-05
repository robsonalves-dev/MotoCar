import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'salvar_viagem_page.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RotasPage extends StatefulWidget {
  const RotasPage({super.key});

  @override
  State<RotasPage> createState() => _RotasPageState();
}

class _RotasPageState extends State<RotasPage> {
  final origemController = TextEditingController();
  final destinoController = TextEditingController();
  final consumoController = TextEditingController();
  final precoCombustivelController = TextEditingController();

  String combustivel = 'Gasolina';

  bool carregando = false;
  String mensagem = '';

  double? distanciaKm;
  double? tempoMinutos;
  double? litrosNecessarios;
  double? custoViagem;

  static const Color azulMotoCar = Color(0xFF1565C0);
  static const Color fundo = Color(0xFFF5F7FA);

  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  Future<void> calcularRota() async {
    final origem = origemController.text.trim();
    final destino = destinoController.text.trim();

    final consumo = double.tryParse(
      consumoController.text.replaceAll(',', '.'),
    );

    final precoCombustivel = double.tryParse(
      precoCombustivelController.text.replaceAll(',', '.'),
    );

    if (origem.isEmpty ||
        destino.isEmpty ||
        consumo == null ||
        precoCombustivel == null ||
        consumo <= 0 ||
        precoCombustivel <= 0) {
      setState(() {
        mensagem =
            'Informe origem, destino, consumo e preço do combustível.';
        distanciaKm = null;
        tempoMinutos = null;
        litrosNecessarios = null;
        custoViagem = null;
      });
      return;
    }

    setState(() {
      carregando = true;
      mensagem = '';
      distanciaKm = null;
      tempoMinutos = null;
      litrosNecessarios = null;
      custoViagem = null;
    });

    try {
      final origemUrl = Uri.encodeComponent(origem);
      final destinoUrl = Uri.encodeComponent(destino);

      final response = await http.get(
        Uri.parse(
          'https://motocarweb.com.br/backend/api/rotas.php'
          '?origem=$origemUrl'
          '&destino=$destinoUrl',
        ),
      );

      final dados = jsonDecode(response.body);

      if (!mounted) {
        return;
      }

      if (dados['status'] != true) {
        setState(() {
          carregando = false;
          mensagem =
              dados['mensagem'] ??
              'Não foi possível calcular a rota.';
        });
        return;
      }

      final rota = dados['rota'];

      final distancia = double.tryParse(
        rota['distancia_km'].toString(),
      );

      final tempo = double.tryParse(
        rota['tempo_minutos'].toString(),
      );

      if (distancia == null || tempo == null) {
        setState(() {
          carregando = false;
          mensagem = 'Dados da rota inválidos.';
        });
        return;
      }

      final litros = distancia / consumo;
      final custo = litros * precoCombustivel;

      setState(() {
        carregando = false;
        distanciaKm = distancia;
        tempoMinutos = tempo;
        litrosNecessarios = litros;
        custoViagem = custo;
        mensagem = '';
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        carregando = false;
        mensagem = 'Erro ao conectar com a API.';
      });
    }
  }

  Future<void> salvarViagem() async {
    if (distanciaKm == null ||
        tempoMinutos == null ||
        litrosNecessarios == null ||
        custoViagem == null) {
      return;
    }

    final consumo = double.tryParse(
      consumoController.text.replaceAll(',', '.'),
    );

    final precoCombustivel = double.tryParse(
      precoCombustivelController.text.replaceAll(',', '.'),
    );

    if (consumo == null || precoCombustivel == null) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SalvarViagemPage(
          origem: origemController.text.trim(),
          destino: destinoController.text.trim(),
          distanciaKm: distanciaKm!,
          tempoMinutos: tempoMinutos!,
          consumoKmL: consumo,
          precoCombustivel: precoCombustivel,
          combustivel: combustivel,
          litrosNecessarios: litrosNecessarios!,
          custoViagem: custoViagem!,
        ),
      ),
    );
  }

  String formatarTempo(double minutos) {
    final horas = minutos ~/ 60;
    final minutosRestantes = (minutos % 60).round();

    if (horas > 0) {
      return '$horas h $minutosRestantes min';
    }

    return '$minutosRestantes min';
  }

  String formatarValor(double valor) {
    return valor.toStringAsFixed(2).replaceAll('.', ',');
  }

@override
void initState() {
  super.initState();
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

  @override
void dispose() {
  origemController.dispose();
  destinoController.dispose();
  consumoController.dispose();
  precoCombustivelController.dispose();

  _bannerAd?.dispose();

  super.dispose();
}

  InputDecoration campoDecoracao({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: azulMotoCar,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 17,
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
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
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
      crossAxisAlignment: CrossAxisAlignment.start,
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

  Widget itemResultado({
    required IconData icon,
    required String valor,
    required String titulo,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F8FC),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: azulMotoCar,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              valor,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2933),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
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
        elevation: 0,
        surfaceTintColor: Colors.white,
        foregroundColor: const Color(0xFF263238),
        centerTitle: true,
        title: const Text(
          'Rotas',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: Color(0xFF263238),
          ),
        ),
      ),

      bottomNavigationBar: _isBannerAdReady && _bannerAd != null
    ? SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: _bannerAd!.size.height.toDouble(),
          child: Center(
            child: SizedBox(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
          ),
        ),
      )
    : null,

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
  18,
  20,
  18,
  100,
),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informações da viagem',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF263238),
                    ),
                  ),
                  const SizedBox(height: 18),

                  campoSecao(
                    titulo: 'Origem',
                    child: TextField(
                      controller: origemController,
                      keyboardType: TextInputType.streetAddress,
                      textCapitalization:
                          TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      minLines: 1,
                      maxLines: 2,
                      decoration: campoDecoracao(
                        label: 'Endereço de origem',
                        hint:
                            'Ex.: Rua Barão de Campinas, 123, Limeira - SP',
                        icon: Icons.location_on_outlined,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  campoSecao(
                    titulo: 'Destino',
                    child: TextField(
                      controller: destinoController,
                      keyboardType: TextInputType.streetAddress,
                      textCapitalization:
                          TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      minLines: 1,
                      maxLines: 2,
                      decoration: campoDecoracao(
                        label: 'Endereço de destino',
                        hint:
                            'Ex.: Avenida Paulista, 1000, São Paulo - SP',
                        icon: Icons.flag_outlined,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  campoSecao(
                    titulo: 'Consumo do veículo',
                    child: TextField(
                      controller: consumoController,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: campoDecoracao(
                        label: 'Consumo em km/l',
                        hint: 'Ex.: 12',
                        icon: Icons.speed_outlined,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  campoSecao(
                    titulo: 'Combustível',
                    child: DropdownButtonFormField<String>(
                      initialValue: combustivel,
                      decoration: campoDecoracao(
                        label: 'Tipo de combustível',
                        icon: Icons.local_gas_station_outlined,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Gasolina',
                          child: Text('Gasolina'),
                        ),
                        DropdownMenuItem(
                          value: 'Etanol',
                          child: Text('Etanol'),
                        ),
                      ],
                      onChanged: (valor) {
                        if (valor != null) {
                          setState(() {
                            combustivel = valor;
                          });
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  campoSecao(
                    titulo: 'Preço do combustível',
                    child: TextField(
                      controller: precoCombustivelController,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: campoDecoracao(
                        label: 'Preço por litro',
                        hint: 'Ex.: 6,20',
                        icon: Icons.payments_outlined,
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed:
                          carregando ? null : calcularRota,
                      icon: carregando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.route,
                              color: Colors.white,
                            ),
                      label: Text(
                        carregando
                            ? 'Calculando...'
                            : 'Calcular rota',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: azulMotoCar,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            azulMotoCar.withValues(alpha: 0.6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(15),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (mensagem.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4F4),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color(0xFFFFD6D6),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        mensagem,
                        style: const TextStyle(
                          color: Color(0xFFB42318),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (distanciaKm != null &&
                tempoMinutos != null &&
                litrosNecessarios != null &&
                custoViagem != null) ...[
              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
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
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.assistant_direction,
                            color: azulMotoCar,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Resultado da rota',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF263238),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Estimativa da viagem',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        itemResultado(
                          icon: Icons.route,
                          valor:
                              '${formatarValor(distanciaKm!)} km',
                          titulo: 'Distância',
                        ),
                        const SizedBox(width: 10),
                        itemResultado(
                          icon: Icons.access_time,
                          valor:
                              formatarTempo(tempoMinutos!),
                          titulo: 'Tempo estimado',
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.local_gas_station_outlined,
                                color: azulMotoCar,
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Combustível necessário',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF5F6368),
                                  ),
                                ),
                              ),
                              Text(
                                '${formatarValor(litrosNecessarios!)} L',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF263238),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          const Divider(height: 1),

                          const SizedBox(height: 14),

                          Row(
                            children: [
                              const Icon(
                                Icons.payments_outlined,
                                color: azulMotoCar,
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Custo estimado',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF5F6368),
                                  ),
                                ),
                              ),
                              Text(
                                'R\$ ${formatarValor(custoViagem!)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: azulMotoCar,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: salvarViagem,
                        icon: const Icon(
                          Icons.save_outlined,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Salvar viagem',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: azulMotoCar,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(15),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
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