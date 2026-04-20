#!/bin/bash
set -euo pipefail

mkdir -p .build
swiftc \
  Tests/StockModelTests.swift \
  Sources/JugaBar/StockModels.swift \
  Sources/JugaBar/Int+Formatting.swift \
  -o .build/stock-model-tests

./.build/stock-model-tests
