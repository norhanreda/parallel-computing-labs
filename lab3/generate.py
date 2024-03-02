# Function to generate a test file with matrices containing 1s and 2s
def generate_test_file(file_path, rows, columns):
    # content = f"{rows} {columns}\n"
    content = f""

    # Matrix 1 with 1s
    for index in range(rows):
        content += " ".join([str(float(index+1))] * columns) + "\n"

  
    # with open(file_path, 'a') as file:
    file.write(content)

# Specify the file path and matrix dimensions
file_path = 'input_mil .txt'
n_cases = 1
sizes =[(1000000,1)]

with open(file_path, 'a') as file:
    
    # file.write(str(n_cases) + '\n')

    # Generate the test file
    for size in sizes:
        m,n = size
        generate_test_file(file_path, m, n)

print(f"Test file '{file_path}' generated successfully.")