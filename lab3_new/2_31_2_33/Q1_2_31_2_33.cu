//Norhan_Reda_Abdelwahed_2_31
//Hoda_Gamal_Hamouda_2_33

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <assert.h>
#include <iostream>
#include <iomanip>
#include <fstream>
#include <vector>

using namespace std;

// Kernel definition
__global__ void ArrAdd(double *arr, long size,double *result)
{
    extern __shared__ double partialSum[];
    unsigned int t = threadIdx.x;
    
    unsigned int new_size = (size-1) / blockDim.x +1 ;
    partialSum[t] = 0;

    for(int i=0;i<new_size ;i++)
    {
      partialSum[t]+= arr[t*new_size+i];
    }

    if(t >=size)
      return ;
    for(unsigned int stride = 1; stride < blockDim.x; stride *= 2){

        if(t % (2*stride) == 0)
              partialSum[t] += partialSum[t+stride];
        __syncthreads();
    }

    if(t==0)
        *result = partialSum[0];
    }

int main(int argc, char *argv[])
{

    // Specify the file path
    std::string filePath = argv[1];

    // Open the file for reading
    std::ifstream file(filePath);

   if (!file.is_open()) {
        std::cerr << "Error opening file" << std::endl;
        return 1;
    }

    double* array = nullptr;  // Pointer to the array
    double * result = nullptr;
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
     double *result_device;

     result = (double*)malloc(sizeof(double));
     cudaMalloc((void**)&array_device, count * sizeof(long));
     cudaMalloc((void**)&result_device,sizeof(double));

    cudaMemcpy(array_device, array, count * sizeof(long), cudaMemcpyHostToDevice);
    dim3 threadsPerBlock(1024, 1);
    dim3 numBlocks(1, 1);
    ArrAdd<<< numBlocks, threadsPerBlock , threadsPerBlock.x * sizeof(double) >>>(array_device,count,result_device);

    cudaMemcpy( result, result_device, sizeof(double), cudaMemcpyDeviceToHost);

    //cout<<*result<<endl;
    cout << fixed <<setprecision(2) << *result <<endl;

    // Free the dynamically allocated memory in host
    free(array);
    free(result);

    // Free device memory
    cudaFree(array_device);
    cudaFree(result_device);

   return 0;
}
