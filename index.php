<?php
// Redirect sa stare adrese (tata.lukasplayroom.com/public/KulaWireless/) na novu (start.sokak.app)
// Postavljen 15.6.2026. jer .htaccess na ovoj putanji ima AllowOverride None (LiteSpeed ga ignoriše)
header("Location: https://start.sokak.app/", true, 301);
exit;
?>
