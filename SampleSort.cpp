#include <iostream>
#include <iomanip>
#include <chrono>
#include <thread>
#include <vector>
#include <algorithm>
#include "utils.h"

using namespace std;
using namespace std::chrono;

#define SIZE 1000000
#define THREADS std::min(8, static_cast<int>(std::thread::hardware_concurrency()))
#define N 10 // Number of repetitions for averaging

void sort_partition(int *array, int start, int end) {
    sort(array + start, array + end);
}

int main() {
    int *h_array;
    vector<thread> threads;

    high_resolution_clock::time_point start, end;
    double timeElapsed;

    h_array = new int[SIZE];
    random_array(h_array, SIZE);

    timeElapsed = 0;
    for (int j = 0; j < N; j++) {
        // Copy original array to reset it between runs
        int *array_copy = new int[SIZE];
        copy(h_array, h_array + SIZE, array_copy);

        start = high_resolution_clock::now();

        int chunk_size = SIZE / THREADS;

        for (int i = 0; i < THREADS; i++) {
            int start_idx = i * chunk_size;
            int end_idx = (i == THREADS - 1) ? SIZE : start_idx + chunk_size;

            threads.emplace_back(sort_partition, array_copy, start_idx, end_idx);
        }

        // Join all threads
        for (auto &t : threads) {
            if (t.joinable()) {
                t.join();
            }
        }
        threads.clear();

        // Final sort to ensure complete sorting
        sort(array_copy, array_copy + SIZE);

        end = high_resolution_clock::now();
        timeElapsed += duration<double, std::milli>(end - start).count();

        // Copy sorted data back to h_array for the display
        copy(array_copy, array_copy + SIZE, h_array);

        delete[] array_copy;
    }

    // Print the performance metrics
    cout << "Array Size: " << SIZE << endl;
    cout << "Number of Chunks: " << THREADS << endl;
    cout << "Average Time: " << fixed << setprecision(3) << (timeElapsed / N) << " ms\n";

    delete[] h_array;

    return 0;
}
