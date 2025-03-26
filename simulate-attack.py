from qiskit import QuantumCircuit
from qiskit.primitives import Sampler
from qiskit_aer import AerSimulator
import math
import numpy as np

def quantum_period_finding(a, N):
    """
    Simulate quantum period finding
    
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
    # Determine circuit size
    n_qubits = max(math.ceil(math.log2(N)), 4)
    
    # Create quantum circuit
    qc = QuantumCircuit(2*n_qubits, n_qubits)
    
    # Add Hadamard gates to first register
    qc.h(range(n_qubits))
    
    # Simulate measurement
    simulator = AerSimulator()
    sampler = Sampler(simulator)
    
    # Run the circuit
    job = sampler.run(qc, shots=1024)
    result = job.result()
    
    # Find most probable measurement
    counts = result.quasi_dists[0]
    most_probable = max(counts, key=counts.get)
    
    return most_probable

def shors_algorithm(N):
    """
    Implement Shor's algorithm for factoring
    
    Parameters:
    -----------
    N : int
        Number to be factored
    
    Returns:
    --------
    list: Factors of N
    """
    # Handle trivial cases
    if N % 2 == 0:
        return [2, N // 2]
    
    # Try multiple random bases
    for _ in range(10):
        # Choose random base
        a = np.random.randint(2, N-1)
        
        # Check if coprime
        if math.gcd(a, N) != 1:
            return [math.gcd(a, N), N // math.gcd(a, N)]
        
        # Find period
        r = quantum_period_finding(a, N)
        
        # Compute potential factors
        if r % 2 == 0:
            x = pow(a, r//2, N)
            if x != N - 1:
                f1 = math.gcd(x+1, N)
                f2 = math.gcd(x-1, N)
                
                if 1 < f1 < N and 1 < f2 < N:
                    return [f1, f2]
    
    return None

def main():
    # Numbers to factor
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