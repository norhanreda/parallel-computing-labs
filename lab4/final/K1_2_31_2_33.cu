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
#define STB_IMAGE_IMPLEMENTATION
#include <stdio.h>
#include "stb_image.h"
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"
#include <string>
#include <filesystem>
#include <cuda_runtime.h>
using namespace std;

__constant__ float mask[15*15];


// Kernel definition
__global__ void Imgcov3d(int batchSize, float *input, float* output ,unsigned int width, unsigned int height , int maskdim){

    int outRow = blockIdx.y * blockDim.y + threadIdx.y;
    int outCol = blockIdx.x * blockDim.x + threadIdx.x;
    int imageIndex = blockIdx.z * blockDim.z + threadIdx.z;

    if(outRow < height && outCol < width && imageIndex < batchSize) {

      float sum = 0;

      for(int maskdep = 0; maskdep < 3; ++maskdep){
        for(int maskRow = 0; maskRow < maskdim; ++maskRow){
           for(int maskCol = 0; maskCol < maskdim; ++maskCol){

                  int inRow = outRow -(maskdim/2) + maskRow;
                  int inCol = outCol -(maskdim/2) + maskCol;

                  if(inRow < height && inRow >= 0 && inCol < width && inCol >= 0){
                      sum += mask[maskRow * maskdim + maskCol]
                      *input[imageIndex * 3 * width * height + maskdep * width * height + inRow * width + inCol];
                  }
             }
          }
        }

        if(sum < 0){
          sum = 0;
        } else if (sum > 255){
          sum = 255;
        }

        output[imageIndex * width * height + outRow * width + outCol] = sum;
    }

}

int main(int argc, char *argv[]) {

    string folderPath = argv[1];
    string out_path = argv[2];
    int batch_size = stoi(argv[3]);
    string mask_path = argv[4];

    int maskdim;

    // Open the file for reading
    std::ifstream inputFile(mask_path);

    // Check if the file is opened successfully
    if (!inputFile.is_open()) {
        std::cerr << "Error opening file: " <<mask_path  << std::endl;
        return 1; // Exit with an error code
    }

     inputFile >> maskdim ;
     // cout<<"maskdim "<<maskdim<<endl;

    float *h_A, *h_B,*R,*G,*B;
    int rows1,cols1, comp;

    float *h_images;
    int img_index = 0;

    for (const auto& entry : std::filesystem::directory_iterator(folderPath)) {

        if (entry.is_regular_file()) {
            std::string filePath = entry.path().string();

            unsigned char *data = stbi_load(filePath.c_str(), &cols1, &rows1, &comp, 0);

            if(img_index == 0){
              h_images = (float*)malloc(sizeof(float) * batch_size * cols1 * rows1 * comp);
            }

            if (data) {

                /*printf("cols %d\n", cols1);
                printf("rows %d\n", rows1);
                printf("image %s\n", filePath.c_str());
                */

                h_A = (float*)malloc(sizeof(float) *  rows1 * cols1* comp);
                R = (float*)malloc(sizeof(float) *  rows1 * cols1);
                G = (float*)malloc(sizeof(float) *  rows1 * cols1);
                B = (float*)malloc(sizeof(float) *  rows1 * cols1);

                int k = 0;
                for(int i=0;i<rows1 * cols1* comp;i=i+3)
                {
                  R[k] =  static_cast<float>(data[i]);
                  k=k+1;
                }
                k=0;
                for(int i=1;i<rows1 * cols1* comp;i=i+3)
                {
                  G[k] =  static_cast<float>(data[i]);
                  k=k+1;
                }
                k=0;
                for(int i=2;i<rows1 * cols1* comp;i=i+3)
                {
                  B[k] =  static_cast<float>(data[i]);
                  k=k+1;
                }


                memcpy(h_A, R, rows1*cols1 * sizeof(float));
                memcpy(h_A +rows1*cols1 , G, rows1*cols1 * sizeof(float));
                memcpy(h_A+rows1*cols1+rows1*cols1, B, rows1*cols1 * sizeof(float));

                memcpy(h_images + img_index * rows1 * cols1 * 3,                     R, rows1 * cols1 * sizeof(float));
                memcpy(h_images + img_index * rows1 * cols1 * 3 + rows1 * cols1,     G, rows1 * cols1 * sizeof(float));
                memcpy(h_images + img_index * rows1 * cols1 * 3 + rows1 * cols1 * 2, B, rows1 * cols1 * sizeof(float));

                img_index++;

            }
            else {
                // Failed to load the image
                std::cerr << "Failed to load image: " << filePath << std::endl;
            }

           }
      }


      float *d_images_temp = (float*)malloc(sizeof(float) * batch_size * rows1 * cols1 * comp);
      for(int i=0; i<batch_size; i++){
        memcpy(d_images_temp + i * rows1 * cols1 *comp , h_images + i * rows1 * cols1 *comp, rows1 * cols1 *comp * sizeof(float));
      }


    float *d_images;
    cudaMalloc((void**)&d_images, batch_size * rows1 * cols1 * comp * sizeof(float));
    cudaMemcpy(d_images, d_images_temp, batch_size * rows1 * cols1 * comp * sizeof(float), cudaMemcpyHostToDevice);

    float *d_outs;
    cudaMalloc((void**)&d_outs, batch_size * rows1 * cols1 * sizeof(float));

    float *h_outs = (float*)malloc(sizeof(float) * batch_size * rows1 * cols1);

    h_B =(float*)malloc(sizeof(float) * maskdim* maskdim);

    // Read mask elements
    for (int i = 0; i < maskdim; ++i) {
        for (int j = 0; j < maskdim; ++j) {

            int index =  i * maskdim + j;
            inputFile >>  h_B[index];

        }
    }

    // Copy data from host to device
    cudaMemcpyToSymbol(mask, h_B, maskdim * maskdim * sizeof(float), 0, cudaMemcpyHostToDevice);

    
    // Kernel invocation
    dim3 threadsPerBlock(16,16,1);
    dim3 numBlocks((cols1-1) / threadsPerBlock.x + 1, (rows1-1) / threadsPerBlock.y + 1, batch_size);
    Imgcov3d<<<numBlocks, threadsPerBlock>>>(batch_size,d_images, d_outs,cols1,rows1, maskdim);

    cudaMemcpy(h_outs, d_outs, batch_size * rows1 * cols1 * sizeof(float), cudaMemcpyDeviceToHost);

    unsigned char* h_char = (unsigned char*)malloc(sizeof(unsigned char) * rows1 * cols1);

    for(int k=0;k<batch_size;k++){

      for(int i=0;i<rows1*cols1;i++){
         h_char[i]=static_cast<unsigned char>(h_outs[k*rows1*cols1+i]);
      }
      string filename = "./"+out_path+"/"+"image" + std::to_string(k) + ".jpg";
      stbi_write_jpg(filename.c_str(), cols1, rows1, 1, h_char, 100);
    }

    // Free device memory
    cudaFree(d_images);
    cudaFree(d_outs);

    // Free host memory
    free(h_A);
    free(h_B);
    free(R);
    free(G);
    free(B);
    free(h_images);
    free(d_images_temp);
    free(h_outs);
    free(h_char);

  return 0;
}
