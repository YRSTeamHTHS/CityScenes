<?php
$cache_interval = 300;
$cache_filename = "cache.cache";
//header('Content-Type: application/json');

function load_new() {
    global $cache_filename;
    $data = file_get_contents("http://weather.yahooapis.com/forecastrss?w=12761716&u=f");
    if ($data != "") {
        $xml = simplexml_load_string($data);
        $ns='http://xml.weather.yahoo.com/ns/rss/1.0';//define weather namespace
        $units = $xml->channel->children($ns)->units->attributes(); //get temp unit
        foreach($xml->channel->item->children($ns)->condition->attributes() as $key => $val) //iterate through the attributes of current conditions
          $cond[$key]=$val;//returns text,code,temp,date
        $string = $cond['text'].', '.$cond['temp'].' '.$units."\n".$cond['code'];//assemble string
        file_put_contents($cache_filename, $string);
        print $string;
    } else {
        load_cache();
    }
}

function load_cache() {
    global $cache_filename;
    echo file_get_contents($cache_filename);
}

if (file_exists($cache_filename)) {
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
