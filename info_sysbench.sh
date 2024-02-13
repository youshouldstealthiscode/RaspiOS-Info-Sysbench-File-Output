#!/bin/bash
# Shebang line to specify script interpreter, indicating this script should be run with bash

# Constants are predefined values that remain unchanged throughout the script
CPU_MAX_PRIME=20000 # Maximum number for CPU benchmark calculation
MEMORY_TOTAL_SIZE="1G" # Total size for memory benchmarking, set to 1 Gigabyte
FILE_TOTAL_SIZE="1G" # Total size for file I/O benchmarking, set to 1 Gigabyte
FILE_TEST_MODE="rndrw" # File test mode for sysbench, set to random read/write
TEST_TIME=300 # Duration for file I/O test, set to 300 seconds
MAX_REQUESTS=0 # Max requests for the file I/O test, set to 0 to run for the entire test duration

# Function to check if a required package is installed and install it if not
ensure_package_installed() {
    local package=$1 # Local variable 'package' stores the name of the software package to check/install
    if ! command -v $package &> /dev/null; then # Check if package is installed; redirect output to null for silence
        echo "Installing $package..." # Inform user of package installation
        sudo apt-get update && sudo apt-get install -y $package # Update package lists and install package
    fi
}

# Function to run CPU benchmark using sysbench
run_cpu_benchmark() {
    echo "CPU Test:" # Print message indicating start of CPU test
    sysbench cpu --cpu-max-prime=$CPU_MAX_PRIME run # Execute sysbench CPU test with defined max prime number
}

# Function to run memory benchmark using sysbench
run_memory_benchmark() {
    echo "Memory Test:" # Print message indicating start of memory test
    sysbench memory --memory-total-size=$MEMORY_TOTAL_SIZE run # Execute sysbench memory test with defined total size
}

# Function to run disk benchmark using sysbench
run_disk_benchmark() {
    echo "File I/O Test:" # Print message indicating start of file I/O test
    sysbench fileio --file-total-size=$FILE_TOTAL_SIZE prepare # Prepare file system for file I/O test
    sysbench fileio --file-total-size=$FILE_TOTAL_SIZE --file-test-mode=$FILE_TEST_MODE --time=$TEST_TIME --max-requests=$MAX_REQUESTS run # Execute sysbench file I/O test with defined parameters
    sysbench fileio --file-total-size=$FILE_TOTAL_SIZE cleanup # Cleanup after file I/O test
}

# Function to display hardware information
display_hardware_info() {
    echo "Hardware Information:" # Print header for hardware information section
    lscpu # Display CPU architecture information
    echo "" # Print empty line for readability
    free -h # Display memory usage in human-readable format
    echo "" # Print empty line for readability
    df -h # Display disk space usage in human-readable format
    echo "" # Print empty line for readability
}

# Function to display system information
display_system_info() {
    echo "Operating System Information:" # Print header for OS information section
    lsb_release -a # Display Linux distribution information
    echo "Kernel Version:" # Print header for kernel version
    uname -r # Display kernel version
    echo "" # Print empty line for readability
    echo "Network Information:" # Print header for network information section
    ip -br a # Display brief network interface information
    echo "" # Print empty line for readability
}

# Function for interactive file saving
interactive_save() {
    local content=$1 filename # Declare local variables 'content' (data to save) and 'filename' (file name)
    echo "Enter filename:" # Prompt user to enter filename
    read -r filename # Read user input into 'filename' variable
    echo "$content" > "$filename" # Write 'content' to file named 'filename'
    echo "Information saved to $filename" # Inform user of successful save
}

# Function for GUI-based file saving
gui_save() {
    local content=$1 filename # Declare local variables 'content' (data to save) and 'filename' (file name for GUI selection)
    filename=$(zenity --file-selection --save --confirm-overwrite --filename="raspberry_pi_info.txt") # Use Zenity to prompt user for file name and location, with default suggestion
    if [ -n "$filename" ]; then # Check if 'filename' is not empty
        echo "$content" > "$filename" # Write 'content' to file named 'filename'
        zenity --info --text="Information saved to $filename" # Use Zenity to inform user of successful save
    else
        zenity --error --text="No file selected. Exiting." # Use Zenity to show error if no file was selected
        exit 1 # Exit script with error status
    fi
}

# Main function to orchestrate script execution
main() {
    ensure_package_installed "sysbench" # Ensure sysbench is installed
    ensure_package_installed "zenity" # Ensure Zenity is installed

    local output=$(mktemp) # Create a temporary file and store its path in 'output'
    
    { # Start of command grouping to capture multiple commands' output
        display_hardware_info # Display hardware information
        display_system_info # Display system information
        run_cpu_benchmark # Run CPU benchmark
        run_memory_benchmark # Run memory benchmark
        run_disk_benchmark # Run disk benchmark
    } > "$output" # Redirect all output from the grouped commands to the temporary file

    cat "$output" # Display the contents of the temporary file

    echo "Save information to a file? [y/N]" # Ask user if they want to save the information
    read -r response # Read user's response
    if [[ "$response" =~ ^[Yy]$ ]]; then # Check if response is affirmative
        echo "Choose input method: (k) Keyboard, (g) GUI" # Prompt user to choose input method
        read -r method # Read user's choice

        case "$method" in # Start of case statement to handle input method choice
            k) interactive_save "$(cat "$output")" ;; # If keyboard, call interactive save function
            g) gui_save "$(cat "$output")" ;; # If GUI, call GUI save function
            *) echo "Invalid option. Exiting." ;; # Handle invalid input
        esac
    fi

    rm "$output" # Delete the temporary file to clean up
}

main # Call the main function to start the script
