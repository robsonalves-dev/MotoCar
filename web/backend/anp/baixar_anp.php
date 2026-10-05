<?php

if (php_sapi_name() !== 'cli') {
    http_response_code(403);
    exit('Acesso não permitido.');
}

$url = 'https://www.gov.br/anp/pt-br/assuntos/precos-e-defesa-da-concorrencia/precos/arquivos-lpc/2026/revendas_lpc_2026-09-20_2026-09-26.xlsx';

$arquivoFinal = __DIR__ . '/revendas_anp.xlsx';
$arquivoTemp  = __DIR__ . '/revendas_anp.tmp.xlsx';

echo "Baixando planilha da ANP...\n";

$fp = fopen($arquivoTemp, 'wb');

if (!$fp) {
    die("ERRO: não foi possível criar o arquivo temporário.\n");
}

$ch = curl_init($url);

curl_setopt_array($ch, [
    CURLOPT_FILE => $fp,
    CURLOPT_FOLLOWLOCATION => true,
    CURLOPT_TIMEOUT => 120,
    CURLOPT_CONNECTTIMEOUT => 20,
    CURLOPT_USERAGENT => 'MotoCar/1.0',
    CURLOPT_FAILONERROR => true,
]);

$sucesso = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$erro = curl_error($ch);

curl_close($ch);
fclose($fp);

if (!$sucesso || $httpCode !== 200) {
    @unlink($arquivoTemp);

    die(
        "ERRO ao baixar a planilha.\n" .
        "HTTP: {$httpCode}\n" .
        "Detalhes: {$erro}\n"
    );
}

if (!file_exists($arquivoTemp) || filesize($arquivoTemp) < 10000) {
    @unlink($arquivoTemp);
    die("ERRO: arquivo baixado parece inválido.\n");
}

if (!rename($arquivoTemp, $arquivoFinal)) {
    @unlink($arquivoTemp);
    die("ERRO: não foi possível substituir a planilha antiga.\n");
}

echo "DOWNLOAD CONCLUÍDO!\n";
echo "Arquivo: {$arquivoFinal}\n";
echo "Tamanho: " . filesize($arquivoFinal) . " bytes\n";