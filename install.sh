#!/bin/bash

set -e

echo "📁 Applying UI fixes to /etc/ipwgd..."

# Ensure target directories exist
mkdir -p /etc/ipwgd/frontend/app
mkdir -p /etc/ipwgd/frontend/styles

# Copy fixed layout.tsx
cp layout.tsx /etc/ipwgd/frontend/app/layout.tsx

# Copy fixed globals.css
cp globals.css /etc/ipwgd/frontend/styles/globals.css

# Copy fixed page.tsx
cp page.tsx /etc/ipwgd/frontend/app/page.tsx

# Copy README
cp README.md /etc/ipwgd/README.md

echo "✅ All files have been updated successfully."
echo "📦 You can now run: cd /etc/ipwgd/frontend && npm run build"
