int val;
int ptr;

void main() {
    val = 42;
    ptr = &val;
    val = *(int*)ptr;
}
