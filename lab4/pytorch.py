import torch
import torch.nn.functional as F
import torchvision.transforms as transforms
import cv2
import time
import numpy as np
import sys
import os
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
print(torch.cuda.is_available())

# Define the mask tensor
file_path = sys.argv[4]

# Open the file in read mode
with open(file_path, "r") as file:
    # Read the lines of the file
    lines = file.readlines()

# Remove any leading or trailing whitespace characters from each line
lines = [line.strip() for line in lines]

# Extract the first line and assign it to a variable
MASKDIM = int(lines[0])
print("maskdim", MASKDIM)
# Extract the remaining lines and create a matrix
mask = [(line.split()) for line in lines[1:]]
# Convert the list to a numpy array
array_2d = np.array(mask, dtype=float)

mask = np.repeat(array_2d[np.newaxis, ...], 3, axis=0)

print(mask)

# Process the variables
print("MASKDIM:", MASKDIM)
print("Matrix:")
# for row in mask:
#     print(row)
print("mask shape",mask.shape)

# Convert the mask to a PyTorch tensor
mask = torch.from_numpy(mask)

print(mask)

mask = mask.unsqueeze(0).unsqueeze(0)[:,:3,:,:,:]
mask = mask.float()

# Folder path containing the images
input_path = sys.argv[1]
output_path = sys.argv[2]
# List all image file names in the folder
image_files = os.listdir(input_path)

imageShape0 = None 
imageShape1 = None 
# Define the allowed image formats
allowed_formats = (".jpg", ".jpeg", ".png")
# Create an empty list to store the preprocessed images
image_list = []
# Iterate over the image files
for image_file in image_files:
   # Check if the file has one of the allowed formats
  if image_file.lower().endswith(allowed_formats):
    print(image_file)
    # Read the RGB image using OpenCV
    image = cv2.imread(os.path.join(input_path, image_file))
    imageShape0 =  image.shape[0] 
    imageShape1 =  image.shape[1] 
    image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    print("image file",image_file)
    
    # print(image[0])
    image_array = np.array(image)
    max_value = np.max(image_array)
    max_value_arg = np.argmax(image_array)
    # print('===>', max_value, max_value_arg)

    # Define the padding size
    padding = (MASKDIM - 1) // 2
    print(padding)

    pad_height = (padding, padding)  # Pad 2 pixels on each side along height
    pad_width = (padding, padding)  # Pad 2 pixels on each side along width
    pad_channels = (0, 0)  # No padding along channels (RGB)

    # Pad the image
    padded_image = np.pad(image, (pad_height, pad_width, pad_channels), mode='constant', constant_values=0)  # Pad with zeros
    print(padded_image.shape)
    print("Data type of input_image:", padded_image.dtype)
    # Convert the image to a PyTorch tensor
    transform = transforms.ToTensor()
    input_image = transform(padded_image)
    print(input_image.shape)
    print("Data type of input_image:", input_image.dtype)

    input_image = input_image * 255

    # Append the tensor to the image list
    image_list.append(input_image)

# Stack the image tensors into a single tensor along the batch dimension
batch_images = torch.stack(image_list, dim=0)

# # Reshape the tensor to match the expected shape (batch_size, channels, depth, height, width)
# batch_images = batch_images.unsqueeze(2).expand(-1, -1, desired_dims[0], -1, -1)
batch_images = batch_images.unsqueeze(1)
print("batch_images shape",batch_images.shape)
print("mask size",mask.shape)
# Perform the 3D convolution using PyTorch
# Start the timer
start_time = time.time()
output_tensor = F.conv3d(batch_images, mask)
print("output tensor",output_tensor.shape)
# Stop the timer
end_time = time.time()
output_tensor = output_tensor.to(torch.int)
output_tensor = output_tensor.squeeze(2).numpy()
print("output tensor",output_tensor.shape)
print("shape",output_tensor.shape[0])
if not os.path.exists(output_path):
    # Create the folder using os.mkdir()
    os.mkdir(output_path)
    print(f"Folder created at: {output_path}")
else:
    print(f"Folder already exists at: {output_path}")
for i in range(output_tensor.shape[0]):
  output_array = output_tensor[i]
  print(output_array.shape)
  output_array = np.clip(output_array, 0, 255)  # Clip values to the range [0, 255]
  print(output_array)
  cv2.imwrite(output_path+'/'+'image'+str(i)+'.jpg', output_array.reshape(imageShape0 , imageShape1, 1))


