
//Norhan_Reda_Abdelwahed_2_31
//#include <iostream>
#include <stdio.h>
#include <stdlib.h>
//using namespace std;
int concat(int a, int b) {
    int temp = b;
    while (temp > 0) {
        a *= 10;
        temp /= 10;
    }
    return a + b;
}
	int main(int argc, char *argv[])
{
    int r,c,index;
    int sum = 0;
    r = atoi(argv[1]);
    c = atoi(argv[2]);
     if (argc != 3 + r * c) {
        printf("Invalid number of elements provided.\n");
        return 1;
    }


    int* arr[r];
    int colsum [c];

    for (int i = 0 ; i<r;i++)
    {
        arr[i] = (int*)malloc(c*sizeof(int));
    }
  index=3;
  for(int i =0 ; i<r;i++){
       for(int j=0;j<c;j++)
        {
            arr[i][j]=atoi(argv[index]);
            index++;
        }
  }
  for(int i = 0; i<c;i++)
  {
    colsum[i]=0;
  }
      for(int i =0 ; i<r;i++){
       for(int j=0;j<c;j++)
        {
             colsum[j] = concat(colsum[j],arr[i][j]);
        }

  }
/* printf("the original array\n");
   for(int i =0 ; i<r;i++){
       for(int j=0;j<c;j++)
        {

            printf("%d ",arr[i][j]);
        }
       printf("\n");
  }

printf("the column sum array\n");*/
  for(int i= 0 ; i<c;i++)
  {

    //printf("%d ",colsum[i]);
    sum+=colsum[i];
  }

  //printf("\nsummition: ");

	printf("%d",sum);

	return 0;
}
