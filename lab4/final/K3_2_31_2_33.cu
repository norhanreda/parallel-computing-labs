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


__global__ void Imgcov3d(int batchSize, float *input, float* output, unsigned int width,unsigned int height,int maskdim, int shared_width,int shared_height, int shared_depth){

  extern __shared__ float sharedTile [];

    int tx = threadIdx.x;
    int ty = threadIdx.y;

    int tile_x = shared_width - (maskdim - 1);
    int tile_y = shared_height - (maskdim - 1);

    int x_o = blockIdx.x * tile_x + threadIdx.x;
    int y_o = blockIdx.y * tile_y + threadIdx.y;
    int idx = blockIdx.z * blockDim.z + threadIdx.z;

    if (idx >= batchSize){
      return;
    }

    // number of pixels each thread should get from input image
    int num = ((shared_width*shared_height) - 1) /(tile_x*tile_y) + 1;

    // each thread gets 'num' pixel (its 3 channels) from input image
    for (int d=0; d< 3; d++){
      for(int f=0; f < num ; f++){

          int element_index = tile_x * tile_y * f + ty * tile_x + tx;

          // get col, row in shared memory
          int dx = element_index % shared_width;
          element_index = element_index / shared_width;
          int dy = element_index % shared_height;

          // get col, row in input image
          int x_i = dx + blockIdx.x * tile_x - maskdim/2;
          int y_i = dy + blockIdx.y * tile_y - maskdim/2;

          if(x_i >= 0 && y_i >= 0 && x_i < width && y_i < height){
                sharedTile[d * shared_height * shared_width + dy * shared_width + dx]
                = input[idx * width * height * 3 + d * height * width + y_i * width + x_i];
          }
          else{
              sharedTile[d * shared_height * shared_width + dy * shared_width + dx] = 0.0;
          }
      }
    }

    __syncthreads();


  // all threads contribute in calculating the output
  if(y_o < height && x_o < width){

  float sum = 0;

    for(int y_mask = 0; y_mask < maskdim; y_mask++) {
            for(int x_mask = 0; x_mask < maskdim; x_mask++) {
                  for(int z_mask = 0; z_mask < 3; z_mask++) {
                    sum += mask[y_mask * maskdim + x_mask] *
                    sharedTile[z_mask * shared_height * shared_width + (ty + y_mask) * shared_width +(tx + x_mask)];

                }
            }
        }

    if(sum < 0){
      sum = 0;
    } else if (sum > 255){
      sum = 255;
    }

        output[idx * width * height + y_o * width + x_o] = sum;
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
     //cout<<"maskdim "<<maskdim<<endl;

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

    int tile_x = threadsPerBlock.x;
    int tile_y = threadsPerBlock.y;

    int x_blocks = (cols1 + tile_x - 1) / tile_x;
    int y_blocks = (rows1 + tile_y - 1) / tile_y;
    int z_blocks = batch_size;

    int shared_width = tile_x + maskdim - 1;
    int shared_height = tile_y + maskdim - 1;
    int shared_depth = threadsPerBlock.z;

    dim3 numBlocks(x_blocks, y_blocks, z_blocks);

    Imgcov3d<<<numBlocks, threadsPerBlock,(sizeof(float)*shared_width*shared_height*3*shared_depth)>>>(batch_size,d_images,d_outs,cols1,rows1, maskdim,shared_width,shared_height,shared_depth);

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
