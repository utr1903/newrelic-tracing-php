#!/bin/bash

makeRestCall() {

  local method=$1

  echo -e "---\n"

  curl -X $method "http://localhost:8080/proxy" \
    -i \
    -H "Content-Type: application/json"

  echo -e "\n"
  sleep 2
}

while true
do
  # returns 201
  for i in {1..5}
  do
    makeRestCall "POST"
  done

  # returns 400
  makeRestCall "DELETE"

  # returns 200
  for i in {1..5}
  do
    makeRestCall "GET"
  done

  # returns 400
  makeRestCall "PATCH"
done
