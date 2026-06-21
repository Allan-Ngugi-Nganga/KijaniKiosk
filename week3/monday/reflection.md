# Reflection

## The `/proc` boundary
The `/proc` directory is not a real filesystem located on the hard drive; it is a virtual pseudo-filesystem created dynamically by the Linux kernel in RAM. It acts as a live window into the kernel's internal data structures. When you run a command like `ps aux`, it is actually reading text files dynamically generated inside `/proc` (like `/proc/[PID]/status`). 

Because `/proc` exists purely in memory and represents the live state of the operating system, its contents do not persist after a reboot. When the power cycles, the RAM is cleared, the kernel restarts, and a completely new state is generated. This tells us that the data investigated during triage is highly ephemeral—if a server reboots before we capture process states or memory maps, the exact conditions of the incident are permanently lost.

## Kernel space and process isolation
A runaway user-space process cannot corrupt kernel memory because of hardware-enforced memory isolation, specifically Virtual Memory and protection rings. The operating system uses the CPU's Memory Management Unit (MMU) to give every user process its own isolated virtual address space. The process behaves as if it owns the memory, but the MMU maps it to physical RAM. 

Furthermore, user processes run in an unprivileged execution mode (Ring 3), while the kernel runs in a highly privileged mode (Ring 0). If a user process tries to access memory outside its mapped virtual space or tries to touch kernel memory, the CPU throws a hardware exception, and the kernel terminates the process (a segmentation fault). If this boundary did not exist, a single memory leak or bad pointer in a basic web server application could overwrite core operating system instructions, crashing the entire machine instantly.

## The triage pipeline you built
The most complex pipeline from the lab was the error frequency counter: 
`grep -E "ERROR|WARN|CRITICAL" /var/log/kijanikiosk/app.log | awk '{print $4}' | sort | uniq -c | sort -rn`

1. **`grep -E ...`**: Scans the log and outputs only the lines containing the specified severity keywords.
2. **`awk '{print $4}'`**: Takes the output from `grep` and strips away everything except the fourth word (the specific error type).
3. **`sort`**: Takes the list of error words and arranges them alphabetically. This is a critical prerequisite. 
4. **`uniq -c`**: Scans the sorted list, squashes identical adjacent lines into a single line, and prefixes it with a count.
5. **`sort -rn`**: Takes the counted list and sorts it numerically (`-n`) in reverse (`-r`), bringing the most frequent errors to the top.

If we reversed `sort` and `uniq -c` (running `uniq` before sorting), the pipeline would break. `uniq` only compares *adjacent* lines. If the errors were scattered chronologically, `uniq` would fail to group them, resulting in multiple separate lines for the same error type with fragmented counts.

## Containers and the kernel
A Docker container is not a traditional Virtual Machine; it does not have its own guest kernel or hypervisor. Instead, a container is simply a standard Linux process (or group of processes) running directly on the host's kernel. 

The host system can see these processes in `ps aux` because the host kernel is the entity actively scheduling and managing them. The "isolation" of a container is an illusion provided to the process *inside* the container, primarily using two Linux kernel features: **Namespaces** (which restrict what the process can see, like network interfaces or other PIDs) and **Control Groups / cgroups** (which restrict what the process can use, like limiting CPU or RAM). To the process inside the container, it looks like it is alone on a machine. To the host, it is just another PID.

## Operational consequence
The log evidence reveals a classic cascading failure where the database bottleneck starved the entire system. At 03:45, the database connection pool began reaching capacity, finally exhausting entirely at 04:07. Because the Node.js application could no longer check out a database connection, it began queuing incoming API requests. 

When an asynchronous application like Node.js queues requests waiting for I/O, it must keep those connections open and hold their execution contexts in memory. As the queries timed out (04:08), the backlog of unresolved requests piled up, causing a massive spike in memory consumption (triggering the 87% memory warning at 04:09). The memory pressure was a secondary symptom of the application holding onto stalled traffic. Ultimately, the database dropped offline completely (06:22), turning the latency degradation into a total outage.