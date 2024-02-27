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
#define N 800
// Kernel definition
__global__ void MatMul(float *A, float *B, float *C, int rows, int cols)
{
    int row = blockIdx.y * blockDim.y + threadIdx.y;

    if (row < rows) {
        float element = 0.0f;
        for (int col = 0; col < cols; col++) {
            element += A[row * cols + col] * B[col];
        }
        C[row] = element;
    }

}

int main(int argc, char *argv[])
{


    // Specify the file path
    std::string filePath = argv[1];

    // Open the file for reading
    std::ifstream inputFile(filePath);
    std::string outputFilePath = argv[2];
    // Check if the file is opened successfully
    if (!inputFile.is_open()) {
        std::cerr << "Error opening file: " << filePath << std::endl;
        return 1; // Exit with an error code
    }

    // Open the output file for writing
    std::ofstream outputFile(outputFilePath);
      // Check if the output file is opened successfully
    if (!outputFile.is_open()) {
        std::cerr << "Error opening output file: " << outputFilePath << std::endl;
        inputFile.close(); // Close the input file before exiting
        return 1; // Exit with an error code
    }


    // Read the number of test cases
    int numTestCases;
    int rows ;
    int cols;
    inputFile >> numTestCases;

    // Process each test case
    for (int testCase = 1; testCase <= numTestCases; ++testCase) {
        std::cout << "Test Case " << testCase << ":" << std::endl;

        // Read the number of rows and columns for the current test case

        inputFile >> rows >> cols;

        cout<<rows<<","<<cols<<endl;
    float *h_A, *h_B, *h_C;
    float *d_A, *d_B, *d_C;

    // Allocate host memory
    h_A = (float*)malloc(sizeof(float) * rows * cols);
    h_B =(float*)malloc(sizeof(float) * cols *1 );
    h_C = (float*)malloc(sizeof(float) * rows * 1);

    // Populate matrices h_A and h_B

    // Allocate device memory
    cudaMalloc((void**)&d_A, rows * cols * sizeof(float));
    cudaMalloc((void**)&d_B, cols * 1 * sizeof(float));
    cudaMalloc((void**)&d_C, rows * 1 * sizeof(float));




        // Read matrix1 elements
        for (int i = 0; i < rows; ++i) {
            for (int j = 0; j < cols; ++j) {
                inputFile >> h_A[i * cols + j];
            }
        }

        // Read matrix2 elements
        for (int i = 0; i < cols; ++i) {

                inputFile >> h_B[i ];

        }

        // Print matrices for the current test case (you can replace this with your specific logic)
        std::cout << "Matrix1:" << std::endl;
        for (int i = 0; i < rows; ++i) {
            for (int j = 0; j < cols; ++j) {
                std::cout << h_A[i * cols + j] << " ";
            }
            std::cout << std::endl;
        }

        std::cout << "Matrix2:" << std::endl;
        for (int i = 0; i < cols; ++i) {
            for (int j = 0; j < 1; ++j) {
                std::cout << h_B[i * cols + j] << " ";
            }
            std::cout << std::endl;
        }

      // Copy data from host to device
    cudaMemcpy(d_A, h_A, rows * cols * sizeof(float), cudaMemcpyHostToDevice);
    cudaMemcpy(d_B, h_B, cols * 1 * sizeof(float), cudaMemcpyHostToDevice);



    //...
    // Kernel invocation with one block of N * N * 1 threads
    dim3 threadsPerBlock(32, 32);
    dim3 numBlocks((cols-1) / threadsPerBlock.x+1,(rows-1) / threadsPerBlock.y+1);
    MatMul<<<numBlocks, threadsPerBlock>>>(d_A, d_B, d_C,rows,cols);




    //...
    // Copy the result matrix C from device to host
    cudaMemcpy(h_C, d_C, rows * 1 * sizeof(float), cudaMemcpyDeviceToHost);

    printf("h_C[0] = %f\n", h_C[0]);
    printf("PASSED\n");
    // Write matrices for the current test case to the output file

       for (int i = 0; i < rows; ++i) {

                outputFile << h_C[i]<<" ";

            outputFile << std::endl;
        }

    // Free device memory
    cudaFree(d_A);
    cudaFree(d_B);
    cudaFree(d_C);

    // Free host memory
    free(h_A);
    free(h_B);
    free(h_C);

    }

    // Close the file
    inputFile.close();
    outputFile.close();

   return 0;
}
