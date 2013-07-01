<?php
$cache_interval = 60;
$cache_filename = "cache.cache";
//header('Content-Type: application/json');

function load_new() {
    global $cache_filename;
    $data = file_get_contents("http://citibikenyc.com/stations/json");
    if ($data != "") {
        file_put_contents($cache_filename, $data);
        echo $data;
    } else {
        load_cache();
    }
}

function load_cache() {
    global $cache_filename;
    echo file_get_contents($cache_filename);
}

if (file_exists($cahce_filename)) {
    $cache_time = filemtime($cache_filename);
    $current_time = time();
    if ($current_time - $cache_time > $cache_interval || $cache_time > $current_time) {
        load_new();
    } else {
        load_cache();
    }
} else {
    load_new();
}
