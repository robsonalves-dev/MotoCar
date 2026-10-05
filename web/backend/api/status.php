<?php

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

header('Content-Type: application/json; charset=utf-8');

echo json_encode([
    'status' => true,
    'api' => 'MotoCar',
    'mensagem' => 'Backend online!'
]);