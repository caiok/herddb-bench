#!/bin/bash

set -x -e -u

# Simple healtcheck on Herd port
nc -z localhost ${HERD_PORT}
