#!/usr/bin/python
import pycuda.driver as cuda
import pycuda.autoinit

import numpy
import random
import math

binomial_kernel = """
#include <stdio.h>
#include <stdlib.h>


#define real float

////////////////////////////////////////////////////////////////////////////////                                                                                         
// Global types                                                                                                                                                          
////////////////////////////////////////////////////////////////////////////////                                                                                         
typedef struct{
    float S;
    float X;
    float T;
    float R;
    float V;
}TOptionData;


////////////////////////////////////////////////////////////////////////////////                                                                                         
// Global parameters                                                                                                                                                     
////////////////////////////////////////////////////////////////////////////////                                                                                         
//Number of time steps                                                                                                                                                   
#define   NUM_STEPS 256
#define MAX_OPTIONS 1024


////////////////////////////////////////////////////////////////////////////////
// Internal GPU-side constants and data structures
////////////////////////////////////////////////////////////////////////////////
#define  TIME_STEPS 16
#define CACHE_DELTA (2 * TIME_STEPS)
#define  CACHE_SIZE (256)
#define  CACHE_STEP (CACHE_SIZE - CACHE_DELTA)

#if NUM_STEPS % CACHE_DELTA
    #error Bad constants
#endif

//Preprocessed input option data
typedef struct{
    real S;
    real X;
    real vDt;
    real puByDf;
    real pdByDf;
} __TOptionData;

__device__            real d_CallBuffer[MAX_OPTIONS * (NUM_STEPS + 16)];

////////////////////////////////////////////////////////////////////////////////
// Overloaded shortcut functions for different precision modes
////////////////////////////////////////////////////////////////////////////////
#ifndef DOUBLE_PRECISION
__device__ inline float expiryCallValue(float S, float X, float vDt, int i){
    real d = S * expf(vDt * (2.0f * i - NUM_STEPS)) - X;
    return (d > 0) ? d : 0;
}
#else
__device__ inline double expiryCallValue(double S, double X, double vDt, int i){
    double d = S * exp(vDt * (2.0 * i - NUM_STEPS)) - X;
    return (d > 0) ? d : 0;
}
#endif

////////////////////////////////////////////////////////////////////////////////
// GPU kernel
////////////////////////////////////////////////////////////////////////////////
__global__ void binomialOptionsKernel(__TOptionData *d_OptionData, float *d_CallValue){
    __shared__ real callA[CACHE_SIZE];
    __shared__ real callB[CACHE_SIZE];
    //Global memory frame for current option (thread block)
    real *const d_Call = &d_CallBuffer[blockIdx.x * (NUM_STEPS + 16)];

    const int       tid = threadIdx.x;
    const real      S = d_OptionData[blockIdx.x].S;
    const real      X = d_OptionData[blockIdx.x].X;
    const real    vDt = d_OptionData[blockIdx.x].vDt;
    const real puByDf = d_OptionData[blockIdx.x].puByDf;
    const real pdByDf = d_OptionData[blockIdx.x].pdByDf;

    //Compute values at expiry date
    for(int i = tid; i <= NUM_STEPS; i += CACHE_SIZE)
        d_Call[i] = expiryCallValue(S, X, vDt, i);

    //Walk down binomial tree
    //So double-buffer and synchronize to avoid read-after-write hazards.
    for(int i = NUM_STEPS; i > 0; i -= CACHE_DELTA)
        for(int c_base = 0; c_base < i; c_base += CACHE_STEP){
            //Start and end positions within shared memory cache
            int c_start = min(CACHE_SIZE - 1, i - c_base);
            int c_end   = c_start - CACHE_DELTA;

            //Read data(with apron) to shared memory
            __syncthreads();
            if(tid <= c_start)
                callA[tid] = d_Call[c_base + tid];

            //Calculations within shared memory
            for(int k = c_start - 1; k >= c_end;){
                //Compute discounted expected value
                __syncthreads();
                if(tid <= k)
                    callB[tid] = puByDf * callA[tid + 1] + pdByDf * callA[tid];
                k--;

                //Compute discounted expected value
                __syncthreads();
                if(tid <= k)
                    callA[tid] = puByDf * callB[tid + 1] + pdByDf * callB[tid];
                k--;
            }

            //Flush shared memory cache
            __syncthreads();
            if(tid <= c_end)
                d_Call[c_base + tid] = callA[tid];
    }

    //Write the value at the top of the tree to destination buffer
    if(threadIdx.x == 0) d_CallValue[blockIdx.x] = (float)callA[0];
}

"""

class OptionData(object):
    def __init__(self,S,X,T,R,V):
        self.S = S
        self.X = X
        self.T = T
        self.R = R
        self.V = V

def binomialOptionFromProcessed(processed):
    stepsNum = 256
    spotPrice = processed[0]
    strikePrice = processed[1]
    vDt = processed[2]
    puByDf = processed[3]
    pdByDf = processed[4]
    prices = []
    u = math.exp(vDt)
    d = math.exp(-vDt)
    uu = u*u
    prices.append(spotPrice * pow(d,stepsNum))
    for i in xrange(1, stepsNum+1):
        prices.append(uu*prices[i-1])
    callValues = []
    for i in xrange(stepsNum+1):
        callValues.append(max(0.0, (prices[i] - strikePrice)))
    for i in xrange(stepsNum, 0, -1):
        for j in xrange(i):
            callValues[j] = (puByDf*callValues[j+1] + pdByDf*callValues[j])
    return callValues[0]

def binomialOptionsGPU(optionData, module):
    h_OptionData = []
    comps = []

    for data in optionData:
        T = data.T
        R = data.R
        V = data.V

        dt = T / 256
        vDt = V * math.sqrt(dt)
        rDt = R * dt
        #Per-step interest and discount factors
        If = math.exp(rDt)
        Df = math.exp(-rDt)
        #Values and pseudoprobabilities of upward and downward moves
        u = math.exp(vDt)
        d = math.exp(-vDt)
        pu = (If - d) / (u - d)
        pd = 1.0 - pu
        puByDf = pu * Df
        pdByDf = pd * Df
        processed = [data.S, data.X, vDt, puByDf, pdByDf]
        #print processed
        h_OptionData.append(processed)
        comp = binomialOptionFromProcessed(processed)
        comps.append(comp)
    array = numpy.array(h_OptionData,dtype=numpy.float32)

    a_gpu = cuda.to_device(array)
    b_gpu = cuda.mem_alloc(len(h_OptionData))
    func = mod.get_function("binomialOptionsKernel")
    print "Loaded function..."
    func(a_gpu, b_gpu, block=(5,1,1), grid=(len(h_OptionData),1))
    result = numpy.zeros((len(h_OptionData),1),dtype=numpy.float32)
    cuda.memcpy_dtoh(result,b_gpu)
    return zip(result.tolist(),comps)

optionData = []
for i in range(100):
    optionData.append(OptionData(random.uniform(5.0,30.0),random.uniform(1.0,100.0),random.uniform(0.25,10.0),0.06,0.10))
mod = cuda.SourceModule(binomial_kernel)
result = binomialOptionsGPU(optionData,mod)
for res,comp in result:
    print str(comp)+" : "+str(res[0])

