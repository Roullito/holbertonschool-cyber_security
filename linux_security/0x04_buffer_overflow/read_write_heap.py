#!/usr/bin/python3


"""Read and write a string in the heap of a running process."""

import sys


def usage():
    """Print usage message and exit."""

    print("Usage: {} pid search_string replace_string".format(sys.argv[0]))
    sys.exit(1)


def get_heap_range(pid):
    """Return the start and end addresses of the heap."""

    maps_path = "/proc/{}/maps".format(pid)

    with open(maps_path, "r") as maps_file:
        for line in maps_file:
            if "[heap]" in line:
                region = line.split()[0]
                start, end = region.split("-")

                return int(start, 16), int(end, 16)
        return None, None


def read_write_heap(pid, search_string, replace_string):
    """
    Search for a string in a process's heap memory and replace
    it with another string.

    This function locates a target string within
    the heap memory of a specified process
    and overwrites it with a replacement string.
    The replacement string must not be longer
    than the original search string to prevent memory overflow.

    Args:
        pid (int): The process ID of the target process.
        search_string (str): The string to search for in the heap memory.
        replace_string (str): The string to replace the search_string with.
        Must not be
        longer than search_string.

    Returns:
        None

    Raises:
        SystemExit: If:
            - The heap memory range cannot be found for the process
            - The replacement string is longer than the search string
            - The search string is not found in the heap memory

    Side Effects:
        - Opens and modifies the process memory at /proc/{pid}/mem
        - Terminates the program with exit code 1 on error

    Example:
        read_write_heap(1234, "old_value", "new_val")
    """

    start, end = get_heap_range(pid)

    if start is None or end is None:
        print("memory zone not found")
        sys.exit(1)

    mem_path = "/proc/{}/mem".format(pid)

    search_bytes = search_string.encode("ascii")
    replace_bytes = replace_string.encode("ascii")

    if len(replace_bytes) > len(search_bytes):
        print("replace_string is longer than search_string")
        sys.exit(1)

    with open(mem_path, "rb+") as mem_file:
        mem_file.seek(start)
        heap = mem_file.read(end - start)
        offset = heap.find(search_bytes)
        if offset == -1:
            print("String not found")
            sys.exit(1)

        address = start + offset
        payload = replace_bytes+(b"\x00"*len(search_bytes)-len(replace_bytes))
        mem_file.seek(address)
        mem_file.write(payload)


if __name__ == "__main__":
    if len(sys.argv) != 4:
        usage()
    read_write_heap(sys.argv[1], sys.argv[2], sys.argv[3])
