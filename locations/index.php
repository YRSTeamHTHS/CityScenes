<?php
$files = scandir("./");
$csvs = array();
foreach ($files as $file) {
    if (substr($file, -4, 4) == ".csv") {
        array_push($csvs, $file);
    }
}
header("Content-Type: application/json");
echo json_encode($csvs);