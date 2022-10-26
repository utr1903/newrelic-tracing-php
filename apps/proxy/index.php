<?php

declare(strict_types=1);

require __DIR__ . "/vendor/autoload.php";

use Monolog\Logger;

# Init logger
$logger = new Logger("my_logger");

spl_autoload_register(function ($class) {
    require __DIR__ . "/$class.php";
});

header("Content-type: application/json; charset=UTF-8");

$logger->info("Parsing request URI...");
$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$parts = explode("/", $uri);

if ($parts[1] != "proxy") {
  $logger->error("Endpoint does not exist.");
  http_response_code(404);
  echo json_encode(["message" => "Endpoint does not exist."]);
  exit;
}
else {
  $logger->info("Request URI is parsed successfully.");
}

# Error generation
$persistenceError500 = FALSE;
$persistenceErrorWait = FALSE;

if (count($parts) > 2) {
  if ($parts[2] == "proxy-error-500") {
    $logger->error("Persistence service is not available.");
    newrelic_notice_error("Persistence service is not available.");

    http_response_code(500);
    $responseDto = array(
      "message" => "Unexpected error occured.",
      "statusCode" => 500,
      "data" => NULL,
    );
    echo json_encode($responseDto);
    exit;
  }
  elseif ($parts[2] == "proxy-error-wait") {
    sleep(3);
  }
  elseif ($parts[2] == "persistence-error-500") {
    $persistenceError500 = TRUE;
  }
  elseif ($parts[2] == "persistence-error-wait") {
    $persistenceErrorWait = TRUE;
  }
}

$persistenceServiceEndpoint = "http://persistence-php:80/persistence";
if ($persistenceError500 == TRUE) {
  $persistenceServiceEndpoint = $persistenceServiceEndpoint . "/persistence-error-500";
}
elseif ($persistenceErrorWait == TRUE) {
  $persistenceServiceEndpoint = $persistenceServiceEndpoint . "/persistence-error-wait";
}

if ($_SERVER["REQUEST_METHOD"] == "GET") {
  $logger->info("GET endpoint is triggered. Executing...");

  try {
    $ch = curl_init();
    $headers = array(
      "Accept: application/json",
      "Content-Type: application/json",
    );
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    curl_setopt($ch, CURLOPT_URL, $persistenceServiceEndpoint);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    $result = curl_exec($ch);
    curl_close($ch);

    $logger->info("Request to persistence service is succeeded.");
  }
  catch (Exception $e) {
    $logger->error("Request to persistence service is failed." . $e->getMessage());
    newrelic_notice_error("Request to persistence service is failed.", $e);

    http_response_code(500);
    $responseDto = array(
      "message" => "Request to persistence service failed. " . $e->getMessage(),
      "statusCode" => 500,
      "data" => NULL,
    );
    echo json_encode($responseDto);
    exit;
  }

  if ($result === FALSE) {
    $logger->error("Request to persistence service is failed.");
    newrelic_notice_error("Request to persistence service is failed.");

    http_response_code(500);
    $responseDto = array(
      "message" => "Request to persistence service failed.",
      "statusCode" => 500,
      "data" => NULL,
    );
    echo json_encode($responseDto);
    exit;
  }
  else {
    $logger->info("GET method is executed successfully.");
    http_response_code(json_decode($result, true)["statusCode"]);
    echo $result;
    exit;
  }
}
elseif ($_SERVER["REQUEST_METHOD"] == "POST") {
  $logger->info("POST endpoint is triggered. Executing...");
  
  $requestDto = array(
    "value" => 10,
    "tag" => "POST",
  );

  try {
    $ch = curl_init();
    $headers = array(
      "Accept: application/json",
      "Content-Type: application/json",
    );
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    curl_setopt($ch, CURLOPT_URL, $persistenceServiceEndpoint);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $requestDto);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    $result = curl_exec($ch);
    curl_close($ch);

    $logger->info("Request to persistence service is succeeded.");

    if ($result === FALSE) {
      $logger->error("Request to persistence service is failed.");
      newrelic_notice_error("Request to persistence service is failed.");

      http_response_code(500);
      $responseDto = array(
        "message" => "Request to persistence service failed.",
        "statusCode" => 500,
        "data" => NULL,
      );
      echo json_encode($responseDto);
    }
    else {
      $logger->info("POST method is executed successfully.");
      http_response_code(201);
      echo $result;
    }
  }
  catch (Exception $e) {
    $logger->error("Request to persistence service is failed." . $e->getMessage());
    newrelic_notice_error("Request to persistence service is failed.", $e);

    http_response_code(500);
    $responseDto = array(
      "message" => "Request to persistence service failed. " . $e->getMessage(),
      "statusCode" => 500,
      "data" => NULL,
    );
    echo json_encode($responseDto);
  }
  exit;
}
elseif ($_SERVER["REQUEST_METHOD"] == "DELETE") {
  $logger->info("DELETE endpoint is triggered. Executing...");

  try {
    $ch = curl_init();
    $headers = array(
      "Accept: application/json",
      "Content-Type: application/json",
    );
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    curl_setopt($ch, CURLOPT_URL, $persistenceServiceEndpoint);
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, "DELETE");
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    $result = curl_exec($ch);
    curl_close($ch);

    $logger->info("Request to persistence service is succeeded.");
  }
  catch (Exception $e) {
    $logger->error("Request to persistence service is failed.");
    http_response_code(500);
    $responseDto = array(
      "message" => "Request to persistence service failed. " . $e->getMessage(),
      "statusCode" => 500,
      "data" => NULL,
    );
    echo json_encode($responseDto);
    exit;
  }

  if ($result === FALSE) {
    $logger->error("Request to persistence service is failed.");
    newrelic_notice_error("Request to persistence service is failed.");

    http_response_code(500);
    $responseDto = array(
      "message" => "Request to persistence service failed.",
      "statusCode" => 500,
      "data" => NULL,
    );
    echo json_encode($responseDto);
    exit;
  }
  else {
    $logger->info("DELETE method is executed successfully.");
    http_response_code(200);
    echo $result;
    exit;
  }
}
else {
  $logger->warning("Only GET, POST and DELETE methods are allowed.");

  http_response_code(400);
  $responseDto = array(
    "message" => "Only GET, POST and DELETE methods are allowed.",
    "statusCode" => 400,
    "data" => NULL,
  );
  echo json_encode($responseDto);
  exit;
}
