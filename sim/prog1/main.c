int main(void) {
    extern int testStart;
    extern int arrAddr;
    extern int arrSize;

    int idxI, idxJ, idxK;
    int swapTmp;

    // copy 32 elements from arrAddr to testStart
    for (idxK = 0; idxK < 32; idxK++) {
        *(&testStart + idxK) = *(&arrAddr + idxK);
    }

    // bubble sort on testStart
    for (idxI = 0; idxI < *(&arrSize) - 1; idxI++) {
        for (idxJ = 0; idxJ < *(&arrSize) - 1 - idxI; idxJ++) {
            if (*(&testStart + idxJ) > *(&testStart + idxJ + 1)) {
                swapTmp = *(&testStart + idxJ);
                *(&testStart + idxJ) = *(&testStart + idxJ + 1);
                *(&testStart + idxJ + 1) = swapTmp;
            }
        }
    }

    return 0;
}
