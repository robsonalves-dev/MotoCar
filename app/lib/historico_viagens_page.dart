import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'editar_viagem_page.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';

class HistoricoViagensPage extends StatefulWidget {
  const HistoricoViagensPage({super.key});

  @override
  State<HistoricoViagensPage> createState() =>
      _HistoricoViagensPageState();
}

class _HistoricoViagensPageState
    extends State<HistoricoViagensPage> {
  List<dynamic> viagens = [];

  bool carregando = true;
  String mensagem = '';

  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  final String listaUrl =
      'https://motocarweb.com.br/backend/api/viagens.php';

  final String apiUrl =
      'https://motocarweb.com.br/backend/api/viagens.php';

  @override
void initState() {
  super.initState();
  carregarViagens();
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

  Future<void> carregarViagens() async {
    setState(() {
      carregando = true;
      mensagem = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioId = prefs.getInt('usuario_id');

      if (usuarioId == null || usuarioId <= 0) {
        setState(() {
          carregando = false;
          mensagem =
              'Usuário não identificado. Faça login novamente.';
        });
        return;
      }

      final response = await http.get(
        Uri.parse('$listaUrl?usuario_id=$usuarioId'),
      );

      final dados = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        carregando = false;

        if (dados['status'] == true) {
          viagens = dados['viagens'] ?? [];

          if (viagens.isEmpty) {
            mensagem = 'Nenhuma viagem registrada.';
          }
        } else {
          mensagem =
              dados['mensagem'] ??
              'Erro ao carregar viagens.';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        carregando = false;
        mensagem = 'Erro ao conectar com a API.';
      });
    }
  }

  Future<void> excluirViagem(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir viagem'),
          content: const Text(
            'Tem certeza que deseja excluir esta viagem?',
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
      final prefs = await SharedPreferences.getInstance();
      final usuarioId = prefs.getInt('usuario_id');

      if (usuarioId == null || usuarioId <= 0) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuário não identificado.'),
          ),
        );

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

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            dados['mensagem'] ??
                'Operação concluída.',
          ),
        ),
      );

      if (dados['status'] == true) {
        carregarViagens();
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Erro ao conectar com a API.',
          ),
        ),
      );
    }
  }

  String formatarNumero(dynamic valor) {
    final numero = double.tryParse(
      valor.toString().replaceAll(',', '.'),
    );

    if (numero == null) {
      return '-';
    }

    return numero
        .toStringAsFixed(2)
        .replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de viagens'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: carregarViagens,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
          ),
        ],
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

      body: carregando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : viagens.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      mensagem.isEmpty
                          ? 'Nenhuma viagem registrada.'
                          : mensagem,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: carregarViagens,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: viagens.length,
                    itemBuilder: (context, index) {
                      final viagem = viagens[index];

                      return Card(
                        margin: const EdgeInsets.only(
                          bottom: 12,
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.route),
                          ),
                          title: Text(
                            '${viagem['origem']} → '
                            '${viagem['destino']}',
                          ),
                          subtitle: Text(
                            'Distância: '
                            '${formatarNumero(
                              viagem['distancia_km'],
                            )} km\n'
                            'Combustível: '
                            '${viagem['combustivel']}\n'
                            'Custo: R\$ '
                            '${formatarNumero(
                              viagem['custo_viagem'],
                            )}\n'
                            'Litros: '
                            '${formatarNumero(
                              viagem['litros_necessarios'],
                            )}',
                          ),
                          isThreeLine: true,
                          trailing: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    IconButton(
      icon: const Icon(Icons.edit),
      tooltip: 'Editar',
      onPressed: () async {
        final resultado = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditarViagemPage(
              id: int.parse(viagem['id'].toString()),
              origem: viagem['origem'].toString(),
              destino: viagem['destino'].toString(),
              distanciaKm: double.tryParse(
                    viagem['distancia_km'].toString().replaceAll(',', '.'),
                  ) ??
                  0,
              tempoMinutos: double.tryParse(
                    viagem['tempo_minutos'].toString().replaceAll(',', '.'),
                  ) ??
                  0,
              combustivel: viagem['combustivel'].toString(),
              consumoKmL: double.tryParse(
                    viagem['consumo_km_l'].toString().replaceAll(',', '.'),
                  ) ??
                  0,
              precoCombustivel: double.tryParse(
                    viagem['preco_combustivel'].toString().replaceAll(',', '.'),
                  ) ??
                  0,
              litrosNecessarios: double.tryParse(
                    viagem['litros_necessarios'].toString().replaceAll(',', '.'),
                  ) ??
                  0,
              custoViagem: double.tryParse(
                    viagem['custo_viagem'].toString().replaceAll(',', '.'),
                  ) ??
                  0,
            ),
          ),
        );

        if (resultado == true) {
          carregarViagens();
        }
      },
    ),
    IconButton(
      icon: const Icon(Icons.delete),
      tooltip: 'Excluir',
      onPressed: () {
        excluirViagem(
          int.parse(
            viagem['id'].toString(),
          ),
        );
      },
    ),
  ],
),
                        ),
                      );
                    },
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