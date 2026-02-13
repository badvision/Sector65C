; === Comprehensive Test Program ===
; 20-variable test with function calls, all arithmetic, comparisons, and control flow

test_source:
    !text "int a; int b; int c; int d; int e; int f; int g; int h; int i; int j;", $0A
    !text "int k; int l; int m; int n; int o; int p; int q; int r; int s; int t;", $0A
    !text "void add_five() {", $0A
    !text "  t = t + 5;", $0A
    !text "}", $0A
    !text "void main() {", $0A
    !text "  a = 42;", $0A
    !text "  b = 0xFF;", $0A
    !text "  c = 100 + 200;", $0A
    !text "  d = 500 - 123;", $0A
    !text "  e = 25 * 12;", $0A
    !text "  f = 1000 / 7;", $0A
    !text "  g = 1000 % 7;", $0A
    !text "  h = (f * 7) + g;", $0A
    !text "  i = -1;", $0A
    !text "  j = 0xFF & 0x0F;", $0A
    !text "  k = 0xF0 | 0x0F;", $0A
    !text "  l = 0xFF ^ 0x0F;", $0A
    !text "  m = 1 << 8;", $0A
    !text "  n = 256 >> 4;", $0A
    !text "  o = 0;", $0A
    !text "  if (1 > 0) { o = o + 1; }", $0A
    !text "  if (0 < 1) { o = o + 1; }", $0A
    !text "  if (1 == 1) { o = o + 1; }", $0A
    !text "  if (1 != 0) { o = o + 1; }", $0A
    !text "  if (0 <= 1) { o = o + 1; }", $0A
    !text "  if (1 >= 1) { o = o + 1; }", $0A
    !text "  p = 0;", $0A
    !text "  b = 1;", $0A
    !text "  while (b <= 10) {", $0A
    !text "    p = p + b;", $0A
    !text "    b = b + 1;", $0A
    !text "  }", $0A
    !text "  q = 1 && 1;", $0A
    !text "  r = 0 || 1;", $0A
    !text "  s = (5 * 3) - 1;", $0A
    !text "  t = 30000;", $0A
    !text "  add_five();", $0A
    !text "}", $0A
    !byte 0
