///given data as double N-dimensional vectors x and y, this function aims to fits the function P[0] + P[1]*cos( P[2] *x)
using namespace::std;

#include <stdlib.h>
#include <time.h>
#include <math.h>
#include <stdio.h>
#include <fstream>
#include <iostream>
#include <string>
#include <cmath>
#include "nr3matlab.h"
#include "ran.h"

typedef std::vector<double> Double1D;
typedef std::vector<Double1D> Double2D;
template <typename T>
T square(T val) {
	return (val)*(val);
}

Ran my_ran((unsigned) time(0)); ///initialize the random number generator with the current time: the internal state is kept in this global object

///define a functor: this can be called as a function of the vector P for minimization. the data as x and y are stored internally in this functor
class F
{
public:
    double operator()(Double1D &P);
    Double1D x;
    Double1D y;
};

double F::operator()(Double1D &P)
{
    double sum=0.0;
    for(unsigned int ct=0; ct<x.size(); ct++)   sum+=square(y[ct] - (P[0] + P[1]*(cos( P[2] * x[ct] ) )) );
    return sum;
}

#define runs_from_T_ini 10
#define iterations_per_fixed_T 20
double T_initial;   ///this is set later from the typical value of the cost function
#define decrease_T_factor 0.97
#define T_low_threshold 1E-5


#include "simulated_annealing.cpp"
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    VecDoub x_indata(prhs[0]);
    VecDoub y_indata(prhs[1]);
    F my_functor;

    ///now copy data from Matlab input vectors into x and y arrays of functor
    for (int i=0;i<x_indata.size();i++) my_functor.x.push_back(x_indata[i]);
    for (int i=0;i<y_indata.size();i++) my_functor.y.push_back(y_indata[i]);

    double y_mean=mean(my_functor.y);
    double x_scale=max(my_functor.x)-min(my_functor.x);
    double y_scale=max(my_functor.y)-min(my_functor.y);

    Double1D P_ini= {y_mean,y_scale, 10.0/x_scale};
    Double1D step_size{0.1*y_mean,0.1*y_scale, 0.1/x_scale};
    T_initial=10*my_functor(P_ini);

    Double1D P_best;
    double best_f_val;
    simulated_annealing(P_ini, P_best, best_f_val,  my_functor, step_size);

    VecDoub outdata(P_best.size(),plhs[0]);
    for (int i=0;i<P_best.size();i++)outdata[i] =P_best[i];
    }
































