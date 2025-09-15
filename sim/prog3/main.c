// main.c — Greatest Common Divisor (Euclidean algorithm)

int main(void) {
    extern int _test_start;   
    extern int div1;        
    extern int div2;         

    int a = *(&div1);
    int b = *(&div2);

    if (a < 0) a = -a;
    if (b < 0) b = -b;

    while (b != 0) {
        int t = a % b;
        a = b;
        b = t;
    }

    *(&_test_start) = a;

    return 0;
}
