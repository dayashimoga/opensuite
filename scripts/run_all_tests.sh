#!/bin/bash
set -e

echo "🔍 Running Static Analysis across all packages..."
for dir in packages/core packages/storage packages/ui_kit packages/l10n apps/opensuite; do
  echo "----------------------------------------"
  echo "Analyzing $dir..."
  echo "----------------------------------------"
  (cd "$dir" && flutter analyze)
done

echo "----------------------------------------"
echo "✅ Static Analysis Completed Successfully!"
echo "----------------------------------------"

echo "🧪 Running Tests across all packages..."
for dir in packages/core packages/storage apps/opensuite; do
  echo "----------------------------------------"
  echo "Running tests in $dir..."
  echo "----------------------------------------"
  (cd "$dir" && flutter test --coverage)
done

echo "----------------------------------------"
echo "✅ All Tests Passed Successfully!"
echo "----------------------------------------"
