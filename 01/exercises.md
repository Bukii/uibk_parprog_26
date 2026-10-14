# Assignment 01

## Exercise 1

- Study how to submit jobs in SLURM, how to check their state and how to cancel them.
    - submit in two ways: via script (recommended) or as a command line
    - for the script see *job.slurm*
    - state check: `squ` short for `squeue -U $USER`
    - cancellation: scancel *<job_id>*
- In your opionion, what are the 5 most important parameters available when submitting a job and why? What are possible settings of these parameters, and what effect do they have?
    - *--job-name <type_string>*: makes it easier to find your job in squeue
    - *--output <type_file>*: redirect output stream (stdout) to any file for validating what's happening
    - *--error <type_file>*: redirect error stream (stderr) for debugging purposes
    - *--mail-user <email_address>*: for jobs that take longer, you can exit the ssh connection and leave the job. When something is happening (job is running, ended, etc.) you get notified
    - *--time=<type_time>*: sometimes programs might be corrupt and end up taking longer as wanted, then this can be very handy. <type_time> must minutes, days-hours, or [[days-]hours:]minutes[:seconds]
- How do you run your program in parallel? What environment setup is required?
    - use *--ntasks=<n_tasks>* to specify the number of task slots
    - with *--ntasks-per-node=<n_tasks_per_node>* (trivial explaination)
    - IMPORTANT: use `srun ./whatever` in your script, otherwise it will only execute once.
    - Also, your program needs to be written in a parallel manner to work properly. Otherwise, it will just execute #N number of times

## Exercise 2

- Interpret the output and describe what information you can gather.
    - 2 sockets (L#0 and L#1), each having 6 cores and 2 processing units per core
    - 31 GB RAM per socket
    - each core has its own L1 and L2 cache
    - L3 cache is shared between all 6 cores of one socket
    - disc mounted on sda (135 GB)
    - 2 eth onboard interfaces eno1 and eno2
    - 2 NIC interfaces (enp...)
    - other PIC devices
- Can you retrieve the number of CPUs and cores from the output?
    - physical chips (CPU): 2
    - number of cores: 12 total (6 per CPU)
- Investigate the memory hierarchy information provided by lstopo.
    - How much memory (RAM) does the compute node offer?
        - 62 GB total
    - What does the term NUMANode tell you about the memory? Why are there two NUMANodes?
        - Non-Uniform Memory Access: the accessed data can live in either partition (62 GB split into to NUMANodes). This can heavily impact latency. Data that is stored on the same socket as the processing unit requesting it, is handled a lot faster than fetching it from the other NUMANode on the other socket
        - because there are also 2 sockets (CPUs). Having a memory for each socket close to the cores, improves latency
    - What interesting information can you retrieve about the caches of the system?
        - L3 is shared between all 6 cores
        - L1 cache is split in data cache and instruction cache
- Is there anything else you can find out from the output?
    - disc mounted on sda (135 GB)
    - 2 eth onboard interfaces eno1 and eno2
    - 2 NIC interfaces (enp...)
    - other PIC devices
- Based on your observations, how many threads could you utilize at maximum when parallelizing a program (e.g. with OpenMP) on this system?
    - 24 = 2 sockets * 6 cores * 2 PUs
- Compare your observations to the CPU documentation. Do your observations match the documentation?
    - yes, in lstopo are just 2 of those CPUs
    - also max memory cap of the CPU docs is way above the actual memory