# ParallelizedDynamics
This project is a means to research the ways to implement fast, performant Julia code. It has two parts,

## Serial, Type Stable Method for Finding a Quantile


[Here](https://github.com/Abhishek-1Bhatt/ParallelizedDynamics/blob/main/rootFinder.jl), I implement an algorithm to find the yth quantile of a  Univariate Distribution. Basically, we have to find the x for which CDF(x) = y. This function has been nicely implemented in [Distributions.jl](https://github.com/JuliaStats/Distributions.jl), and we're gonna test the output against it. To implement it, I interpret this problem as a root finding problem, i.e, we find the root of the equation g(x) = CDF(x) - y. Now to find the root Newton's Method is applied, which is a Discrete Dynamical System converging to the root,

    u_n+1 = u_n - (g(u_n)/g'(u_n))
    
   The initial value is taken as u_o = mean of the given distribution.
   
   
## Generation of Bifurcation Plot for Logistic Map

The logistic equation is the dynamical system given by the update relation:

    x_n+1=rx_n(1−x_n)

where r is some parameter. First we inspect the steady state behaviour of logistic map with x_o = 0.25, r = 2.9, and by running it for 400 iterations to reach the steady state, then we store the next 150 values as a sample of the steady state. We can analytically, calculate the steady state by finding the value for which

    x_n+1 = x_n
    
which is around 0.655, for the above parameters.

Now I have generated a Bifurcation plot for this process to get the steady state behaviour for r in the range 2.9:0.001:4.0 . The data collection process has been benchmarked with the help of @btime macro from [BenchmarkTools.jl](https://github.com/JuliaCI/BenchmarkTools.jl), and the data is collected inside a pre-allocated 1101x150 matrix. All the analysis till now is carried on in [this](https://github.com/Abhishek-1Bhatt/ParallelizedDynamics/blob/main/Logistic_map_serial.jl) file. 

Next [in here](https://github.com/Abhishek-1Bhatt/ParallelizedDynamics/blob/main/Logistic_map_multithread.jl) I parallelize the 1101x150 matrix generation using Multithreading. As 2 threads were available in my computing hardware, I observed around 2x speedup. Thus multithreading was successful because the process we are parallelizing here,i.e., filling the vector of length 150(each column of the matrix) takes in the order of microseconds which is scalable for multithreading as the overhead for multithreading is around 50-100ns.

Then, in [this](https://github.com/Abhishek-1Bhatt/ParallelizedDynamics/blob/main/Logistic_map_multiprocess.jl) file we look at multiprocessing the above process with two worker processes, which gives us two options
1. Using static scheduling of the worker jobs with @distributed for
2. Using dynamic job scheduling of the worker jobs with pmap
It can be expected for @distributed for to perform better because the jobs we're multiprocessing all take almost same time and are of the same length, which turns out to be true.

But when comparing with the serial code discussed above, multiprocessing performs slower. Thus, we don't get any speedup from multiprocessing.
Why? Its simply because the overhead of multiprocessing is of the order of ms, hence this problem was not scalable for multiprocessing.
Besides, pmap performed worst for this case because of the Dynamic Scheduling. This is a valuable lesson to learn that parallelization doesn't always bring speedup.
The results can be arranged in order of slowest to fastest as:

    pmap -> @distributed -> Serial -> Multithreading(Threads.@threads)

Note:Just like pmap and @distributed we can see the effect of static and dynamic scheduling in multithreading with Threads.@threads and Threads.@spawn respectively. Also it is important to understand that static scheduling doesn't always have an advantage over dynamic. For the same problem if our tasks took different amount of time then dynamic scheduling would scale better. Besides, static scheduling is also known as loop based parallelism and dynamic scheduling is named task based scheduling.
