<?php
echo $_SERVER['SERVER_ADDR'];
$containerID= trim(shell_exec("hostname"));
$myPublicIP = trim(shell_exec("curl ifconfig.io"));
echo " Container ID: ".$containerID;
echo " ------------ ";
echo " My public IP: ".$myPublicIP;
phpinfo();
?>

