#!/usr/bin/env bash

# BikerOS Docker Build Runner
# This script builds the BikerOS Docker image and runs the container to build the ISO.

set -e

# Change to the root directory of the Biker-OS repository
cd "$(dirname "$0")/.."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed. Please install Docker and try again."
    exit 1
fi

# Build the Docker image
echo "Building BikerOS Builder Docker image..."
docker build -t biker-os-builder .

# Create the output directory if it doesn't exist
mkdir -p out

# Run the Docker container to build the ISO
# Note: --privileged is often required for mkarchiso inside Docker for mounting operations
echo "Running BikerOS Builder container to build the ISO..."
docker run --privileged --rm \
    -v "$(pwd):/home/builder/Biker-OS" \
    -v "$(pwd)/out:/home/builder/bikeros-build/out" \
    biker-os-builder

echo "Build complete! If successful, the ISO should be in the 'out' directory."
