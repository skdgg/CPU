// main.c
// Sort Algorithm: insertion sort (ascending)

int main(void) {
    extern int _test_start;   
    extern int array_size;    
    extern int array_addr[];  

    int n = array_size;
    int *dst = &_test_start;   
    int *src = array_addr;    

    for (int i = 0; i < n; ++i) {
        dst[i] = src[i];
    }

    for (int i = 1; i < n; ++i) {
        int key = dst[i];
        int j = i - 1;
        while (j >= 0 && dst[j] > key) {
            dst[j + 1] = dst[j];
            --j;
        }
        dst[j + 1] = key;
    }

    return 0;
}
