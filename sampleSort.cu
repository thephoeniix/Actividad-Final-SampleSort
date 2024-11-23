#include <thrust/sort.h>
#include <thrust/execution_policy.h>
#include <cuda_runtime.h>
#include <iostream>
#include <chrono>
#include <algorithm>

// Kernel for sorting chunks of the array
__global__ void sort_kernel(int* data, int chunk_size, int total_size) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    int start = idx * chunk_size;
    int end = min(start + chunk_size, total_size);

    if (start < total_size) {
        // Sort the assigned chunk using Thrust
        thrust::sort(thrust::device, data + start, data + end);
    }
}

// Host function for parallel sample sort
void parallel_samplesort_cuda(int* data, int size, int num_chunks) {
    int chunk_size = size / num_chunks; // Calculate the size of each chunk
    int* d_data;

    // Allocate memory on the device
    cudaMalloc(&d_data, size * sizeof(int));

    // Copy data from host to device
    cudaMemcpy(d_data, data, size * sizeof(int), cudaMemcpyHostToDevice);

    // Launch kernel
    sort_kernel<<<num_chunks, 256>>>(d_data, chunk_size, size);

    // Copy sorted data back from device to host
    cudaMemcpy(data, d_data, size * sizeof(int), cudaMemcpyDeviceToHost);

    // Free device memory
    cudaFree(d_data);
}

int main() {
    const int size = 1024; // Total size of the array
    const int num_chunks = 4; // Number of chunks to divide the array into
    int data[size];
    const int repetitions = 10; // Number of repetitions for averaging

    // Fill the array with random values
    for (int i = 0; i < size; i++) {
        data[i] = rand() % 1000; // Random values between 0 and 999
    }

    // Variables for timing
    double total_time = 0.0;

    // Run the sort multiple times and measure the time
    for (int i = 0; i < repetitions; i++) {
        int temp_data[size];
        std::copy(data, data + size, temp_data); // Copy original data for consistency

        auto start = std::chrono::high_resolution_clock::now();
        parallel_samplesort_cuda(temp_data, size, num_chunks);
        auto end = std::chrono::high_resolution_clock::now();

        std::chrono::duration<double, std::milli> elapsed = end - start;
        total_time += elapsed.count();
    }

    // Calculate the average time
    double average_time = total_time / repetitions;

   
    // Print the average time
    std::cout << "Array Size: " << size << std::endl;
    std::cout << "Number of Chunks: " << num_chunks << std::endl;
    std::cout << "Average Time: " << average_time << " ms" << std::endl;

    return 0;
}
