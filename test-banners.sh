#!/bin/bash

# Test script to show all banners
echo "Testing all 11 banners..."
echo ""

GREEN='\033[0;32m'
NC='\033[0m'

for i in {1..11}; do
    echo "==================== Banner $i ===================="
    echo -e "${GREEN}"
    cat "banners/banner${i}.txt" 2>/dev/null || echo "Banner $i not found"
    echo -e "${NC}"
    echo ""
    sleep 0.5
done

echo "==================== Random Test ===================="
echo "Running alltor help 3 times to show random banners:"
echo ""

for i in {1..3}; do
    echo "--- Run $i ---"
    ./alltor help | head -n 15
    echo ""
    sleep 1
done

