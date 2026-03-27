sdk := `xcrun --sdk iphonesimulator --show-sdk-path`
product := "CooperativePoolDeadlock"
triple := "arm64-apple-ios13.0-simulator"
binary := ".build/arm64-apple-ios-simulator/debug/" + product

reproduce:
    swift build --product {{product}} --sdk "{{sdk}}" --triple {{triple}}
    xcrun simctl boot "iPhone 16 Pro Max" 2>/dev/null || true
    SIMCTL_CHILD_LIBDISPATCH_COOPERATIVE_POOL_STRICT=1 \
        xcrun simctl spawn --standalone booted {{binary}}; \
        EXIT=$?; \
        if [ $EXIT -eq 133 ] || [ $EXIT -eq 1 ]; then \
            echo "\n✓ Process terminated as expected (exit $EXIT) — deadlock reproduced."; \
        else \
            echo "\n⚠ Unexpected exit code: $EXIT"; exit $EXIT; \
        fi
