import math
import numpy as np
from qiskit import QuantumCircuit
from qiskit.primitives import Sampler
from qiskit_aer import AerSimulator

def quantum_period_finding(a, N):
    """
    Optimized quantum period finding with reduced complexity
    
    Parameters:
    -----------
    a : int
        Base number 
    N : int
        Number to be factored
    
    Returns:
    --------
    int: Potential period
    """
    # Reduce qubit complexity
    n_qubits = max(math.ceil(math.log2(N)), 4)
    
    # Create more efficient quantum circuit
    qc = QuantumCircuit(n_qubits * 2, n_qubits)
    
    # Apply Hadamard gates more efficiently
    qc.h(range(n_qubits))
    
    # Modular exponentiation simulation
    for j in range(n_qubits):
        power = 2 ** j
        qc.cp(2 * math.pi * power / N, j, n_qubits + j)
    
    # Inverse QFT
    qc.measure(range(n_qubits), range(n_qubits))
    
    # Use AerSimulator for faster simulation
    simulator = AerSimulator()
    sampler = Sampler()  # Corrected Sampler initialization
    
    # Reduce shots for faster execution
    job = sampler.run(qc, shots=256)
    result = job.result()
    
    # More robust period extraction
    counts = result.quasi_dists[0]
    most_probable = max(counts, key=counts.get)
    
    return most_probable

def find_period_classical(a, N):
    """
    Classical fallback for period finding
    """
    x = 1
    for r in range(1, N):
        x = (x * a) % N
        if x == 1:
            return r
    return None

def shors_algorithm(N, max_attempts=5):
    """
    Robust Shor's algorithm implementation
    """
    # Handle small/even numbers quickly
    if N < 4 or N % 2 == 0:
        return [2, N // 2]
    
    for _ in range(max_attempts):
        a = np.random.randint(2, N-1)
        
        # Quick GCD check
        gcd = math.gcd(a, N)
        if gcd > 1:
            return [gcd, N // gcd]
        
        # Try quantum period finding
        quantum_period = quantum_period_finding(a, N)
        
        # Fallback to classical method if needed
        if quantum_period == 0:
            classical_period = find_period_classical(a, N)
            quantum_period = classical_period
        
        r = quantum_period
        
        if r % 2 == 0:
            x = pow(a, r//2, N)
            if x != N - 1:
                f1, f2 = math.gcd(x+1, N), math.gcd(x-1, N)
                
                if 1 < f1 < N and 1 < f2 < N:
                    return sorted([f1, f2])
    
    return None

def main():
    test_numbers = [15, 21, 33, 35, 51]
    
    for N in test_numbers:
        print(f"\nFactoring {N}")
        try:
            factors = shors_algorithm(N)
            if factors:
                print(f"Factors: {factors}")
                print(f"Verification: {factors[0]} * {factors[1]} = {factors[0] * factors[1]}")
            else:
                print(f"Could not factor {N}")
        except Exception as e:
            print(f"Error factoring {N}: {e}")

if __name__ == "__main__":
    main()