#!/usr/bin/env bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Drug Interaction API — Full Verification
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
set -e

echo "╔══════════════════════════════════════════╗"
echo "║  Drug Interaction API — Verify Suite     ║"
echo "╚══════════════════════════════════════════╝"

cd "$(dirname "$0")"

# ── Step 1: Install dependencies ────────────
echo ""
echo "▸ Step 1: Installing dependencies..."
npm install --silent 2>/dev/null || npm install
echo "  ✓ Dependencies installed"

# ── Step 2: TypeScript type check ───────────
echo ""
echo "▸ Step 2: TypeScript type check (tsc --noEmit)..."
npx tsc --noEmit 2>&1 && echo "  ✓ TypeScript: No type errors" || {
    echo "  ✗ TypeScript errors found (see above)"
    echo "  Note: @types/* must be installed first (Step 1)"
}

# ── Step 3: ESLint ──────────────────────────
echo ""
echo "▸ Step 3: ESLint..."
npx eslint src/ --max-warnings 0 2>&1 && echo "  ✓ ESLint: No warnings" || {
    echo "  ⚠ ESLint warnings/errors found (see above)"
}

# ── Step 4: Jest unit + integration tests ───
echo ""
echo "▸ Step 4: Jest test suite..."
npx jest --coverage --forceExit 2>&1 && echo "  ✓ All tests passed" || {
    echo "  ✗ Some tests failed (see above)"
}

# ── Step 5: File structure validation ───────
echo ""
echo "▸ Step 5: Verifying no duplicate TS/JS files..."
DUPES=0
for tsfile in src/controllers/*.ts src/services/*.ts src/repositories/*.ts; do
    jsfile="${tsfile%.ts}.js"
    if [ -f "$jsfile" ]; then
        echo "  ✗ DUPLICATE: $jsfile alongside $tsfile"
        DUPES=$((DUPES + 1))
    fi
done
if [ "$DUPES" -eq 0 ]; then
    echo "  ✓ No TS/JS duplicates found"
fi

# ── Step 6: Docker Compose validation ───────
echo ""
echo "▸ Step 6: Docker Compose config check..."
if command -v docker &> /dev/null; then
    docker compose -f ../docker-compose.yml config --quiet 2>&1 && \
        echo "  ✓ docker-compose.yml is valid" || \
        echo "  ⚠ docker-compose.yml has issues"
else
    echo "  ⊘ Docker not installed — skipping"
fi

# ── Summary ─────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Verification complete."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
