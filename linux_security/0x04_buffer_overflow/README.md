## 0. Hack the VM — Find and Replace a String in the Heap of a Running Process

### Goal of the exercise

The goal of this exercise is to write a Python script able to:

- inspect the memory layout of a running process
- locate its **heap**
- search for a specific ASCII string inside that heap
- replace it with another ASCII string

The script must only inspect the **heap** of the target process, not the whole memory space.

Usage:

```bash
read_write_heap.py pid search_string replace_string
```

Example:

```bash
sudo ./read_write_heap.py 6515 Holberton maroua
```

---

### What this exercise teaches

This exercise is a practical introduction to:

- the Linux `/proc` filesystem
- process memory layout
- heap memory
- low-level memory reading and writing
- the relationship between C strings and raw bytes in memory

It is also a good way to understand how data stored in a running process can be modified externally if permissions allow it.

---

### Reminder: what is the heap?

The **heap** is a memory area used for **dynamic allocation**.

In C, functions such as:

- `malloc()`
- `calloc()`
- `realloc()`
- `strdup()`

typically allocate memory on the heap.

In the example program:

```c
s = strdup("Holberton");
```

`strdup()` allocates a new buffer in heap memory and copies `"Holberton"` into it.

That is why the string can later be found in the heap of the running process.

---

### Why `/proc/<pid>/maps` and `/proc/<pid>/mem`?

Linux exposes process information through the `/proc` filesystem.

#### `/proc/<pid>/maps`
This file describes the memory regions of a process.

A typical line may look like this:

```text
555e646e0000-555e64701000 rw-p 00000000 00:00 0 [heap]
```

This line tells us:

- the region starts at `555e646e0000`
- the region ends at `555e64701000`
- this region is the **heap**

#### `/proc/<pid>/mem`
This file gives access to the raw memory of the process.

By seeking to a specific address and reading bytes, we can inspect memory contents.
By writing bytes at a given address, we can modify what is stored in that process memory.

---

### General logic of the script

The script works in five major steps:

1. validate command-line arguments
2. locate the heap range in `/proc/<pid>/maps`
3. open `/proc/<pid>/mem`
4. read only the heap memory range
5. search and replace the target string

---

### Code explanation

#### 1. `usage()`

This function prints the correct usage of the script and exits with status code `1`.

It is called when the number of arguments is invalid.

```python
def usage():
    """Print usage message and exit."""
    print("Usage: {} pid search_string replace_string".format(sys.argv[0]))
    sys.exit(1)
```

Why it matters:
- it makes the script easier to use
- it respects the project requirement for error handling

---

#### 2. `get_heap_range(pid)`

This function reads `/proc/<pid>/maps` and looks for the line containing `[heap]`.

```python
def get_heap_range(pid):
    """Return the start and end addresses of the heap."""
```

Once the heap line is found:

- the first column is extracted
- the `start-end` range is split
- both hexadecimal addresses are converted into integers

Example:

```text
555e646e0000-555e64701000
```

becomes:

- `start = int("555e646e0000", 16)`
- `end = int("555e64701000", 16)`

Why this is important:
- `/proc/<pid>/mem` requires real memory addresses
- the addresses in `maps` are written in hexadecimal

If no heap is found, the function returns:

```python
(None, None)
```

---

#### 3. `read_write_heap(pid, search_string, replace_string)`

This is the core function of the script.

It first calls `get_heap_range(pid)` to retrieve the heap boundaries.

If the heap cannot be found, the script stops.

Then it prepares the path to:

```text
/proc/<pid>/mem
```

and converts both strings to ASCII bytes:

```python
search_bytes = search_string.encode("ascii")
replace_bytes = replace_string.encode("ascii")
```

Why convert to bytes?
Because process memory is not handled as Python strings.
It is handled as raw bytes.

---

#### 4. Preventing unsafe replacement

The script checks that the replacement string is **not longer** than the original one.

```python
if len(replace_bytes) > len(search_bytes):
```

Why?
Because writing a longer string could overwrite adjacent memory and corrupt data.

This is especially important in low-level memory manipulation.

---

#### 5. Reading the heap memory

The memory file is opened in binary read/write mode:

```python
with open(mem_path, "rb+") as mem_file:
```

Then the script moves to the beginning of the heap:

```python
mem_file.seek(start)
```

and reads only the heap:

```python
heap = mem_file.read(end - start)
```

Why only the heap?
Because the exercise explicitly requires searching **only** in the heap.

---

#### 6. Searching for the target string

The script searches for the byte sequence inside the heap:

```python
offset = heap.find(search_bytes)
```

- if the string is found, `offset` is the position in the heap buffer
- if not found, `offset == -1`

Why `offset` is not enough?
Because `offset` is relative to the local Python buffer we just read.
To write back into the target process memory, we need the **real memory address**.

That is why the script computes:

```python
address = start + offset
```

---

#### 7. Building the replacement payload

If the new string is shorter than the old one, the script pads the remaining bytes with null bytes:

```python
payload = replace_bytes + b"\x00" * (len(search_bytes) - len(replace_bytes))
```

Example:

- original string: `"Holberton"` → 9 bytes
- replacement: `"maroua"` → 6 bytes

Payload becomes:

```python
b"maroua\x00\x00\x00"
```

Why is this necessary?
Because C strings end with a null byte (`\0`).
If we do not pad with `\x00`, leftover bytes from the original string may remain visible in memory.

---

#### 8. Writing into process memory

Finally, the script seeks to the exact memory address and writes the new payload:

```python
mem_file.seek(address)
mem_file.write(payload)
```

At that moment, the target process memory is modified.

As a result, the running C program starts printing the new string instead of the old one.

---

### Why this works with the provided C program

The C program stores the result of:

```c
s = strdup("Holberton");
```

in a pointer `s`.

Since `strdup()` allocates memory dynamically, the string is placed in the heap.

The program then continuously prints the contents of `s`.

When the Python script modifies the bytes stored at that heap address, the C program immediately prints the modified string without restarting.

This demonstrates that:

- process memory can be externally inspected
- heap memory contains dynamically allocated data
- modifying those bytes changes program behavior in real time

---

### Important limitations

This script works under specific assumptions:

- the target string must actually be located in the heap
- the process must be accessible with enough permissions
- the replacement string must not be longer than the original
- strings are assumed to be ASCII

This is not a generic memory editor for every situation, but a focused solution for this exercise.

---

### Security perspective

This exercise is educational, but it also highlights important security concepts:

- process memory is sensitive
- poorly protected memory operations can be abused
- low-level memory access requires strict permissions
- understanding memory layout is fundamental in exploitation and defense

It is also directly related to the study of memory corruption vulnerabilities such as buffer overflows.

---

### Key takeaways

After completing this exercise, I understood that:

- the heap stores dynamically allocated data
- `/proc/<pid>/maps` reveals memory regions
- `/proc/<pid>/mem` provides raw access to process memory
- Python can be used for low-level memory inspection on Linux
- replacing bytes in heap memory can change the behavior of a running program

---

# Buffer Overflow Attack Report

> **Suggested top image for the blog post:** a simple diagram showing a process memory layout (`text`, `data`, `heap`, `stack`) with an arrow illustrating data overflowing beyond a buffer boundary.

## Buffer Overflow Attacks: How They Work, Why They Matter, and How to Defend Against Them

Buffer overflows are among the most important memory corruption vulnerabilities in computer security. They have shaped the history of exploitation, influenced operating system defenses, and remain a foundational topic for anyone studying secure programming, vulnerability research, or exploit development.

In this report, I explain what a buffer overflow is, how it happens, how attackers may exploit it, why it has been historically significant, and how developers can reduce the risk of such vulnerabilities.

---

## 1. What is a buffer?

A **buffer** is a contiguous block of memory used to temporarily store data.

Programs use buffers all the time. For example, a program may allocate a buffer to store:

- user input
- file contents
- network packets
- strings
- intermediate computation results

Buffers can exist in different memory regions, such as:

- the **stack**
- the **heap**
- static or global memory

A buffer has a **fixed size**. If a program writes more data than the buffer can hold, the extra data may overwrite adjacent memory.

That is the basis of a **buffer overflow**.

---

## 2. What is a buffer overflow?

A **buffer overflow** happens when a program writes more bytes into a buffer than the buffer was allocated to store.

For example, if a program allocates a buffer of 8 bytes but copies 20 bytes into it without checking the size, the extra 12 bytes will overwrite nearby memory.

This is dangerous because the overwritten memory may contain:

- other variables
- saved frame pointers
- return addresses
- heap metadata
- control structures
- object pointers

Once this happens, the program may crash, misbehave, leak information, or even execute attacker-controlled code.

---

## 3. Why buffer overflows matter in computer security

Buffer overflows are significant because they can directly affect:

- **confidentiality** — by leaking sensitive data
- **integrity** — by modifying memory and program state
- **availability** — by crashing applications or systems
- **execution flow** — by redirecting the program to malicious instructions

Historically, buffer overflows have been one of the most studied and exploited vulnerability classes because they can turn a simple programming mistake into full system compromise.

---

## 4. How do buffer overflows occur?

A buffer overflow usually happens because a program:

- trusts external input too much
- does not validate input length
- copies data unsafely
- uses dangerous functions without bounds checking

Common causes include:

- copying data with functions such as `strcpy()` or `gets()`
- concatenating strings without checking remaining space
- writing past the end of arrays
- miscalculating allocation sizes
- off-by-one mistakes
- integer overflows leading to undersized allocations

At a low level, the issue is simple:

1. the program allocates a buffer
2. more data than expected is written into it
3. neighboring memory is overwritten
4. the overwritten memory changes program behavior

---

## 5. How attackers exploit buffer overflows

An attacker does not exploit a buffer overflow just by causing a crash.
The real goal is usually to **control what gets overwritten**.

A simplified exploitation process often looks like this:

1. identify an input field vulnerable to overflow
2. determine how much data is needed to reach critical memory
3. overwrite nearby control data
4. redirect execution to attacker-controlled logic

Depending on the target, attackers may try to overwrite:

- a return address on the stack
- a function pointer
- a structured exception handler
- heap control metadata
- adjacent object fields or flags

If successful, the attacker may be able to:

- execute arbitrary code
- escalate privileges
- bypass authentication
- crash the program repeatedly
- alter sensitive data in memory

---

## 6. Simplified example of a vulnerable program

Here is a classic unsafe C example:

```c
#include <stdio.h>
#include <string.h>

void vulnerable(char *input)
{
    char buffer[8];
    strcpy(buffer, input);
    printf("You entered: %s\n", buffer);
}
```

Why is it vulnerable?

- `buffer` can only store 8 bytes
- `strcpy()` copies until it reaches a null byte
- if `input` is longer than 7 characters plus `\0`, memory beyond `buffer` is overwritten

For example, an input like:

```text
AAAAAAAAAAAAAAAAAAAA
```

may overwrite nearby stack data.

This is a simplified educational example, but it demonstrates the core issue clearly: **the program performs a write without checking buffer size**.

---

## 7. Stack-based vs heap-based buffer overflows

Buffer overflows are often categorized by where they occur.

### Stack-based buffer overflow
This happens when a local stack buffer is overwritten.

Possible consequences include:
- corruption of local variables
- corruption of saved registers
- overwriting the return address
- redirecting execution flow

This is the classic buffer overflow taught in many exploitation introductions.

### Heap-based buffer overflow
This happens when dynamically allocated memory is overwritten.

Possible consequences include:
- corruption of adjacent heap objects
- corruption of metadata
- modification of application state
- hijacking program behavior through pointers or structures

Heap overflows are often more complex but can be very powerful.

---

## 8. Potential consequences of buffer overflow attacks

The consequences depend on the context, but common impacts include:

- application crashes
- denial of service
- data corruption
- credential theft
- information leakage
- remote code execution
- privilege escalation
- system compromise

In high-value systems, the impact can be severe because a single overflow may provide a path from user input to arbitrary execution.

---

## 9. Historical significance of buffer overflow attacks

Buffer overflows have played a major role in cybersecurity history.

### The Morris Worm (1988)
The Morris Worm is one of the earliest famous examples associated with memory corruption and unsafe software behavior. It spread across Unix systems and demonstrated how software flaws could be weaponized at large scale.

It remains historically important because it showed the real-world consequences of exploitable coding mistakes on networked systems.

### Heartbleed (2014)
Heartbleed is often mentioned alongside memory safety discussions, although technically it is not a classic buffer overflow in the traditional overwrite sense. It was an **out-of-bounds read** in OpenSSL’s heartbeat extension.

Its significance is enormous because it allowed attackers to read sensitive server memory, including possible credentials, private keys, and session data.

This case is a strong reminder that memory safety bugs do not only lead to crashes or code execution — they can also lead to silent and devastating data exposure.

---

## 10. Why C and low-level languages are especially exposed

Languages such as C and C++ provide:

- direct memory access
- pointer arithmetic
- manual memory management
- limited built-in bounds checking

These features make them powerful and efficient, but also dangerous when used carelessly.

A programmer must manually ensure that:

- enough memory is allocated
- copy operations stay within bounds
- null terminators are handled correctly
- indexes remain valid
- lengths are verified before writing

This is why memory-safe coding discipline is essential in low-level development.

---

## 11. Practical ways to reduce the risk

Buffer overflow prevention requires both **secure coding practices** and **system-level mitigations**.

### A. Secure coding practices

#### Validate all input sizes
Never trust external input. Always verify lengths before copying or writing data.

#### Avoid dangerous functions
Unsafe functions such as:
- `gets()`
- `strcpy()`
- `strcat()`
- `sprintf()`

should be avoided or replaced with safer alternatives.

#### Use bounded functions carefully
Functions such as:
- `fgets()`
- `snprintf()`
- `strncpy()`

can help, but only if used correctly.

#### Allocate correct buffer sizes
Always include space for:
- the full data
- the null terminator
- any required metadata or formatting

#### Prefer safer abstractions
Where appropriate, use higher-level libraries or memory-safe languages that reduce direct exposure to raw memory manipulation.

---

### B. Compiler protections

Modern compilers provide important mitigations.

#### Stack canaries
A known value is placed before critical stack control data.
If an overflow modifies it, the program detects the corruption and aborts.

#### Fortified functions
Some compilers and libc implementations can add extra checks to common functions when buffer sizes are known.

#### Control-flow protections
Modern toolchains may include protections that make it harder to redirect execution through corrupted memory.

---

### C. Operating system protections

#### ASLR (Address Space Layout Randomization)
ASLR randomizes memory addresses, making it harder for attackers to predict where useful code or data is located.

#### DEP / NX (Data Execution Prevention)
Marks memory pages as non-executable when appropriate, preventing attackers from simply injecting and running shellcode in writable memory.

#### RELRO, PIE, and other hardening options
These measures make exploitation more difficult by reducing predictable memory layouts and protecting critical linking structures.

---

## 12. Detection and testing strategies

Developers and security testers can detect buffer overflows using:

- code review
- static analysis tools
- dynamic analysis tools
- sanitizers
- fuzzing
- debugger-based testing

### Fuzzing
Fuzzing sends large, malformed, or unexpected inputs to a program to trigger crashes and reveal unsafe memory handling.

### Sanitizers
Tools such as AddressSanitizer can detect invalid writes, out-of-bounds access, and use-after-free bugs during testing.

### Manual review
Reviewing code for unsafe functions, bad assumptions about length, and risky memory operations remains essential.

---

## 13. Key lesson

A buffer overflow is not just “too much data in a buffer.”
It is a memory safety failure that can affect the entire trust model of a program.

A single unchecked write can transform normal input processing into:

- a crash
- a data leak
- a privilege escalation
- or arbitrary code execution

That is why understanding buffer overflows is fundamental for both attackers and defenders.

---

## Conclusion

Buffer overflows remain one of the most important vulnerability classes in cybersecurity because they directly connect insecure programming practices with severe real-world consequences.

They occur when a program writes beyond the boundaries of an allocated buffer, causing memory corruption. Attackers can exploit these bugs to alter control flow, crash systems, steal information, or execute malicious code. Historical examples such as the Morris Worm and memory-safety incidents like Heartbleed demonstrate how serious these flaws can be.

Reducing the risk of buffer overflows requires a combination of:

- secure coding discipline
- careful input validation
- safe memory handling
- compiler hardening
- operating system mitigations
- rigorous testing

In short, preventing buffer overflows is not about one single fix. It is about building software with memory safety in mind from the start.

---

## Suggested image ideas for the blog post

- a process memory layout diagram showing `text`, `data`, `heap`, and `stack`
- a simple illustration of a small buffer being overwritten by larger input
- a screenshot of a debugger showing overwritten memory
- a custom diagram comparing safe copy vs unsafe copy

---

## Suggested short LinkedIn post

I just completed a security write-up on **buffer overflow attacks**.
In this post, I explain what a buffer overflow is, how attackers exploit it, the historical significance of this vulnerability class, and the main strategies used to prevent it in modern systems.
A great topic to better understand memory corruption, secure coding, and low-level software security.

#CyberSecurity #BufferOverflow #Linux #SecureCoding #MemorySafety #HolbertonSchool
