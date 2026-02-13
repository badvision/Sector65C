; === Comprehensive Test Program ===
; 20-variable test with function calls, all arithmetic, comparisons, control flow, and PEMDAS

test_source:
    !text "int a; int b; int c; int d; int e; int f; int g; int h; int i; int j;", $0A
    !text "int k; int l; int m; int n; int o; int p; int q; int r; int s; int t;", $0A
    !text "void add_five() {", $0A
    !text "  t = t + 5;", $0A
    !text "}", $0A
    !text "void main() {", $0A
    !text "  a = (2 + 3) * 4;", $0A
    !text "  b = 2 + 3 * 4;", $0A
    !text "  c = 20 - 12 / 4;", $0A
    !text "  d = 100 - 50 - 25;", $0A
    !text "  e = ((2 + 3) * (4 - 1));", $0A
    !text "  f = (10 + 2) * (8 - 3) / (4 + 1);", $0A
    !text "  g = 2 * 3 + 4 * 5;", $0A
    !text "  h = (5 * 3) + (4 - 1);", $0A
    !text "  i = -1;", $0A
    !text "  j = 10 * (2 + 3);", $0A
    !text "  k = (10 + 20) / (5 + 5);", $0A
    !text "  l = 100 / 10 / 2;", $0A
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
    !text "  s = (2 + 3) * (4 - 1);", $0A
    !text "  t = 30000;", $0A
    !text "  add_five();", $0A
    !text "}", $0A
    !byte 0
