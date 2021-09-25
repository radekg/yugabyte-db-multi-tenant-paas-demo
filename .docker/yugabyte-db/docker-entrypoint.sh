#!/bin/bash

echo "removing old lock files..."
rm -rf /tmp/.yb*
echo "starting YugabyteDB..."
exec "$@"