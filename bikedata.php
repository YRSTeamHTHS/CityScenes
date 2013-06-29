<?php
header('Content-Type: application/json');
echo file_get_contents("http://citibikenyc.com/stations/json");