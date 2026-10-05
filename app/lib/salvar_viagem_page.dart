import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class SalvarViagemPage extends StatefulWidget {
  final String origem;
  final String destino;
  final double distanciaKm;
  final double tempoMinutos;
  final double consumoKmL;
  final double precoCombustivel;
  final String combustivel;
  final double litrosNecessarios;
  final double custoViagem;

  const SalvarViagemPage({
    super.key,
    required this.origem,
    required this.destino,
    required this.distanciaKm,
    required this.tempoMinutos,
    required this.consumoKmL,
    required this.precoCombustivel,
    required this.combustivel,
    required this.litrosNecessarios,
    required this.custoViagem,
  });

  @override
  State<SalvarViagemPage> createState() => _SalvarViagemPageState();
}

class _SalvarViagemPageState extends State<SalvarViagemPage> {
  bool salvando = false;
  String mensagem = '';

  static const Color azulMotoCar = Color(0xFF1565C0);
  static const Color fundo = Color(0xFFF5F7FA);

  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

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

  Future<void> salvarViagem() async {
    setState(() {
      salvando = true;
      mensagem = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      final usuarioId = prefs.getInt('usuario_id');

      if (usuarioId == null || usuarioId <= 0) {
        if (!mounted) return;

        setState(() {
          salvando = false;
          mensagem =
              'Usuário não identificado. Faça login novamente.';
        });

        return;
      }

      final response = await http.post(
        Uri.parse(
          'https://motocarweb.com.br/backend/api/viagens.php',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'usuario_id': usuarioId,
          'veiculo_id': 1,
          'origem': widget.origem,
          'destino': widget.destino,
          'distancia_km': widget.distanciaKm,
          'tempo_minutos': widget.tempoMinutos,
          'combustivel': widget.combustivel.toLowerCase(),
          'consumo_km_l': widget.consumoKmL,
          'preco_combustivel': widget.precoCombustivel,
          'litros_necessarios': widget.litrosNecessarios,
          'custo_viagem': widget.custoViagem,
        }),
      );

      final dados = jsonDecode(response.body);

      if (!mounted) {
        return;
      }

      if (dados['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Viagem salva com sucesso!',
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
            'Não foi possível salvar a viagem.';
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        salvando = false;
        mensagem = 'Erro ao conectar com a API.';
      });
    }
  }

  String formatarNumero(double valor) {
    return valor.toStringAsFixed(2).replaceAll('.', ',');
  }

  String formatarTempo(double minutos) {
    final horas = minutos ~/ 60;
    final minutosRestantes = (minutos % 60).round();

    if (horas > 0) {
      return '$horas h $minutosRestantes min';
    }

    return '$minutosRestantes min';
  }

  Widget itemResumo({
    required IconData icon,
    required String titulo,
    required String valor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
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
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF5F6368),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            valor,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF263238),
            ),
          ),
        ],
      ),
    );
  }

  Widget localCard({
    required IconData icon,
    required String titulo,
    required String endereco,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  endereco,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF263238),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
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
          'Salvar viagem',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: Color(0xFF263238),
          ),
        ),
      ),

bottomNavigationBar: _isBannerAdReady && _bannerAd != null
    ? SafeArea(
        child: Center(
          child: SizedBox(
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          ),
        ),
      )
    : null,

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          18,
          20,
          18,
          30,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumo da viagem',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF263238),
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Confira os dados antes de salvar sua viagem.',
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
                    'Percurso',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF263238),
                    ),
                  ),

                  const SizedBox(height: 16),

                  localCard(
                    icon: Icons.location_on_outlined,
                    titulo: 'Origem',
                    endereco: widget.origem,
                  ),

                  const SizedBox(height: 12),

                  localCard(
                    icon: Icons.flag_outlined,
                    titulo: 'Destino',
                    endereco: widget.destino,
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
                    'Detalhes da viagem',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF263238),
                    ),
                  ),

                  const SizedBox(height: 16),

                  itemResumo(
                    icon: Icons.route,
                    titulo: 'Distância',
                    valor:
                        '${formatarNumero(widget.distanciaKm)} km',
                  ),

                  const SizedBox(height: 10),

                  itemResumo(
                    icon: Icons.access_time,
                    titulo: 'Tempo estimado',
                    valor:
                        formatarTempo(widget.tempoMinutos),
                  ),

                  const SizedBox(height: 10),

                  itemResumo(
                    icon: Icons.local_gas_station_outlined,
                    titulo: 'Combustível',
                    valor: widget.combustivel,
                  ),

                  const SizedBox(height: 10),

                  itemResumo(
                    icon: Icons.speed_outlined,
                    titulo: 'Consumo',
                    valor:
                        '${formatarNumero(widget.consumoKmL)} km/l',
                  ),

                  const SizedBox(height: 10),

                  itemResumo(
                    icon: Icons.water_drop_outlined,
                    titulo: 'Litros necessários',
                    valor:
                        '${formatarNumero(widget.litrosNecessarios)} L',
                  ),

                  const SizedBox(height: 10),

                  itemResumo(
                    icon: Icons.payments_outlined,
                    titulo: 'Preço do combustível',
                    valor:
                        'R\$ ${formatarNumero(widget.precoCombustivel)}',
                  ),

                  const SizedBox(height: 14),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF2FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.payments_outlined,
                            color: azulMotoCar,
                          ),
                        ),
                        const SizedBox(width: 12),
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
                          'R\$ ${formatarNumero(widget.custoViagem)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: azulMotoCar,
                          ),
                        ),
                      ],
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
                onPressed: salvando ? null : salvarViagem,
                icon: salvando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.save_outlined,
                        color: Colors.white,
                      ),
                label: Text(
                  salvando
                      ? 'Salvando...'
                      : 'Salvar viagem',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: azulMotoCar,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      azulMotoCar.withValues(alpha: 0.6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
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
          ],
        ),
      ),
    );
   }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }
}