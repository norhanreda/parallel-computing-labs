
//Norhan_Reda_Abdelwahed_2_31
#include <iostream>
#include <stdio.h>
#include <stdlib.h>
using namespace std;
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
 /*cout <<"the original array"<<endl;
   for(int i =0 ; i<r;i++){
       for(int j=0;j<c;j++)
        {

            cout<<arr[i][j]<<" ";
        }
       cout<<endl;
  }

cout<<"the column sum array"<<endl;*/
  for(int i= 0 ; i<c;i++)
  {
    //cout<<colsum[i]<<" ";
    sum+=colsum[i];
  }

  //cout<<endl;

	cout <<sum;
	return 0;
}
