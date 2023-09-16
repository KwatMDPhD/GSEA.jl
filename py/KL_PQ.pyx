cimport cython
import numpy as np
cimport numpy as np
from libc.math cimport abs, pow, log
from libc.stdlib cimport malloc, free

@cython.boundscheck(False)
@cython.wraparound(False)
@cython.initializedcheck(False)
@cython.nonecheck(False)

cpdef inline compute_KL_PQ_enrichment(
    np.ndarray[np.float_t, ndim=1] S_h, # input gene scores (sorted)
    np.ndarray[np.int_t, ndim=1] I_h, # input indicator vector (1: gene in gene set, 0: gene not in gene set)
    double alpha): # power to raise gene scores

    '''
    Computes the AKL (antisymmetric Kullback-Leibler divergence) GSEA enrichment score for
    one gene set in one gene list
    '''
    
    cdef int i, n = len(S_h)
    cdef np.float_t eps = 1.0e-16
    cdef np.float_t ES, Delta_sum = 0, p_sum = eps, q_sum = eps
    cdef np.ndarray[np.float_t, ndim = 1] P = np.empty(n, dtype = float)
    cdef np.ndarray[np.float_t, ndim = 1] P_rev = np.empty(n, dtype = float)
    cdef np.ndarray[np.float_t, ndim = 1] Q = np.empty(n, dtype = float)
    cdef np.ndarray[np.float_t, ndim = 1] Q_rev = np.empty(n, dtype = float)
    cdef np.ndarray[np.float_t, ndim = 1] Delta = np.empty(n, dtype = float)
    
    # Compute cumulative sums
    
    if alpha == 1.0:
        
        for i in range(n):
            if I_h[i] == 1:
                p_sum += abs(S_h[i]) 

            P[i] = p_sum 
            
            q_sum += 1
            Q[i] = q_sum 

    else:
        
        for i in range(n):
            if I_h[i] == 1:
                p_sum += pow(abs(S_h[i]), alpha) 

            P[i] = p_sum 
            q_sum += 1             
            Q[i] = q_sum 
        
    # Compute cumulative direct and reverse probabilities (shifted one entry to make them match direct prob. 
    # computed from the other side of the gene list)
    
    P[0] = P[0]/p_sum  
    P_rev[0] = 1 
    Q[0] = Q[0]/q_sum 
    Q_rev[0] = 1 
    
    for i in range(1, n):
        P[i] = P[i]/p_sum 
        P_rev[i] = 1 - P[i-1] 
        Q[i] = Q[i]/q_sum 
        Q_rev[i] = 1 - Q[i-1] 
        
    # Compute running enrichment: KL divergence between P and Q minus same quantity from the reverse side
    
    for i in range(n):
        Delta[i] = P[i] * log((P[i] + eps)/(Q[i] + eps)) - P_rev[i] * log((P_rev[i] + eps)/(Q_rev[i] + eps))
        Delta_sum += Delta[i]

    # Final enrichment score
        
    ES = Delta_sum/n
    
    return Delta, ES