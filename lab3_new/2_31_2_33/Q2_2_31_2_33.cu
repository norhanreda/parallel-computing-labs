//Norhan_Reda_Abdelwahed_2_31
//Hoda_Gamal_Hamouda_2_33

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <assert.h>
#include <iostream>
#include <fstream>
#include <vector>

using namespace std;

// Kernel definition
__global__ void BinarySearch(double *array, long size, double target, long *index)
{

    __shared__ long shared_start;
    __shared__ long shared_end;
    __shared__ bool shared_found;
    __shared__ bool target_found;

    int tid = threadIdx.x;

    *index = -1;

    if (tid == 0) {
        shared_start = 0;
        shared_end = size - 1;
        shared_found = false;
        target_found = false;
    }
    __syncthreads();

    while (shared_start <= shared_end && shared_found == false && target_found == false) {

        long elements_per_thread = (shared_end - shared_start + 1 + blockDim.x - 1) / blockDim.x;
        long start = min(shared_start + tid * elements_per_thread, shared_end);
        long end = min(start + elements_per_thread - 1, shared_end);

        /*
        if (end > shared_end) {
            end = shared_end;
        }
        if(start > end){
          start = end;
        }*/


        if (array[start] <= target && target <= array[end]) {
            shared_start = start;
            shared_end = end;
            shared_found = true;
        }

        __syncthreads();

        if (shared_found == false && shared_start == shared_end){
          target_found = true;
          *index = -1;
        }
        else if (shared_found == true && shared_start == shared_end){
          target_found = true;
          *index = shared_start;
        }
        else if(shared_found == false){
           target_found = true;
           *index = -1;
        }
        shared_found = false;

    }
}


int main(int argc, char *argv[])
{


    // Specify the file path
    std::string filePath = argv[1];
    double target = atof(argv[2]);

    // Open the file for reading
    std::ifstream file(filePath);

   if (!file.is_open()) {
        std::cerr << "Error opening file" << std::endl;
        return 1;
    }

    double* array = nullptr;  // Pointer to the array
    long * result = nullptr;
    double value;
    long count = 0;  // Variable to keep track of the number of elements

    // Read elements from the file
    while (file >> value) {
        // Dynamically resize the array
        double* temp = static_cast<double*>(realloc(array, (count + 1) * sizeof(double)));

        if (temp == nullptr) {
            std::cerr << "Error allocating memory" << std::endl;
            free(array);  // Free the previously allocated memory
            return 1;
        }

        array = temp;

        // Add the read value to the array
        array[count] = value;

        count++;
    }

    // Close the file
    file.close();


     // host to device allocation
     double *array_device;
     long *result_device;

     result = (long*)malloc(sizeof(long));

     cudaMalloc((void**)&array_device, count * sizeof(long));
     cudaMalloc((void**)&result_device,sizeof(long));

    cudaMemcpy(array_device, array, count * sizeof(double), cudaMemcpyHostToDevice);


    dim3 threadsPerBlock(1024, 1);
    dim3 numBlocks(1,1);

    BinarySearch<<< numBlocks, threadsPerBlock>>>(array_device,count, target,result_device);

    cudaMemcpy( result, result_device, sizeof(long), cudaMemcpyDeviceToHost);

    cout<<*result<<endl;


    // Free the dynamically allocated memory in host
    free(array);
    free(result);

    // Free device memory
    cudaFree(array_device);
    cudaFree(result_device);

   return 0;
}
