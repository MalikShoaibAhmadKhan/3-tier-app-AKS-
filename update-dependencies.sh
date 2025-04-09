#!/bin/bash
set -e

echo "Updating dependencies for service-a..."
cd service-a
npm install
cd ..

echo "Updating dependencies for service-b..."
cd service-b
npm install
cd ..

echo "All dependencies updated successfully!" 