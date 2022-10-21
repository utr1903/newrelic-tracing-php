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

if ($parts[1] != "persistence") {
  $logger->error("Endpoint does not exist.");
  http_response_code(404);
  echo json_encode(["message" => "Endpoint does not exist."]);
  exit;
}
else {
  $logger->info("Request URI is parsed successfully.");
}

$mysqlServer = getenv('MYSQL_SERVER');
$mysqlUserName = getenv('MYSQL_USERNAME');
$mysqlPassword = getenv('MYSQL_PASSWORD');
$mysqlDatabase = getenv('MYSQL_DATABASE');
$mysqlTable = getenv('MYSQL_TABLE');

# Connect to MySQL
try {
  $logger->info("Connecting to database...");
  $conn = new mysqli($mysqlServer, $mysqlUserName, $mysqlPassword, $mysqlDatabase);
}
catch (Exception $e) {
  $logger->error("Connecting to database is failed." . $e->getMessage());

  http_response_code(500);
    $responseDto = array(
      "message" => "Connection to MySQL DB has failed: " . $e->getMessage(),
      "statusCode" => 500,
      "data" => NULL,
    );
    echo json_encode($responseDto);
    exit;
}

# GET handler
if ($_SERVER["REQUEST_METHOD"] == "GET") {
  $logger->info("GET endpoint is triggered. Executing...");

  $sql = "SELECT id, data FROM " . $mysqlTable;
  $result = $conn->query($sql);

  $counter = 0;
  $data = array();

  if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
      $entry = array(
        "id" => $row["id"],
        "data" => $row["data"],
      );
      $data[$counter] = $entry;
      $counter = $counter + 1;
    }

    http_response_code(200);
    $responseDto = array(
      "message" => "Retrieving values is succeeded.",
      "statusCode" => 200,
      "data" => $data,
    );
    echo json_encode($responseDto);
  }
  else {
    http_response_code(200);
    $responseDto = array(
      "message" => "Retrieving values is succeeded.",
      "statusCode" => 200,
      "data" => NULL,
    );
    echo json_encode($responseDto);
  }
  
  $logger->info("GET method is executed successfully.");
  exit;
}

# POST handler
elseif ($_SERVER["REQUEST_METHOD"] == "POST") {
  $logger->info("POST endpoint is triggered. Executing...");

  $sql = "INSERT INTO " . $mysqlTable . "(data)
  VALUES ('John')";

  if ($conn->query($sql) === TRUE) {
    http_response_code(201);
    $responseDto = array(
      "message" => "Creating new value is succeeded.",
      "statusCode" => 201,
      "data" => NULL,
    );
    echo json_encode($responseDto);
  }
  else {
    http_response_code(500);
    $responseDto = array(
      "message" => "Creating new value is failed." . $conn->error,
      "statusCode" => 500,
      "data" => NULL,
    );
    echo json_encode($responseDto);
  }

  $logger->info("POST method is executed successfully.");
  exit;
}

# DELETE handler
elseif ($_SERVER["REQUEST_METHOD"] == "DELETE") {
  $logger->info("DELETE endpoint is triggered. Executing...");

  $sql = "DELETE FROM " . $mysqlTable;

  if ($conn->query($sql) === TRUE) {
    http_response_code(200);
    $responseDto = array(
      "message" => "Deleting values is succeeded.",
      "statusCode" => 200,
      "data" => NULL,
    );
    echo json_encode($responseDto);
  }
  else {
    http_response_code(500);
    $responseDto = array(
      "message" => "Deleting values is failed." . $conn->error,
      "statusCode" => 500,
      "data" => NULL,
    );
    echo json_encode($responseDto);
  }

  $logger->info("DELETE method is executed successfully.");
  exit;
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
