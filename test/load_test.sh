#!/bin/bash

# Function to check if a command exists
command_exists () {
    type "$1" &> /dev/null ;
}

# Check if figlet is installed
if ! command_exists figlet ; then
    echo "The script requires 'figlet', which is not installed. Please install 'figlet' and run the script again."
    exit 1
fi

# Clear the screen
clear

# Use figlet to create large letters. We center the text with '-c'
figlet -c "No Room for Failure"

# Wait for a moment to let the user read the text
sleep 2

# Begin countdown
for i in 3 2 1
do
    # Clear the screen
    clear

    # Print the countdown large and centered
    figlet -c $i
    
    # Create a more visual delay between the countdown numbers
    sleep 1
done

# Clear the screen
clear

# Print some initiating text
figlet -c "Go!"

# The 'sleep 1' here gives the user a moment to see the 'Go!' text before the screen clears for the 'wrk' command.
sleep 1


# Clear the screen
clear
# Use figlet to create large letters. We center the text with '-c'
echo 'wrk -t2 -c200 -d120s "https://proxy.alexp-aws-test.gitpod.cloud/stats" -c wrk.lua'


# Execute the wrk command and capture its output
wrk_output=$(wrk -t02 -c200 -d120s "https://haproxy-lb-1563643291.eu-central-1.elb.amazonaws.com/" -s wrk.lua)

# Assuming that 'wrk' output contains 'Requests/sec' and 'Non-2xx or 3xx responses:' for error count.
# The awk command is used to parse these values out of the 'wrk' output. This parsing depends on your actual 'wrk' output.

# Extract requests per second
req_per_sec=$(echo "$wrk_output" | awk '/Requests\/sec:/ {print $2}')

# Extract error count
error_count=$(echo "$wrk_output" | awk '/Non-2xx or 3xx responses:/ {print $NF}')

# Extract average latency (you may need to adjust based on your 'wrk' version's output format)
avg_latency=$(echo "$wrk_output" | awk '/Latency/ {print $2}')

# Extract some other metric; replace 'OtherMetric' with the actual metric's label in 'wrk' output
other_metric=$(echo "$wrk_output" | awk '/OtherMetric/ {print $2}')

# Clear the screen before showing the new information
clear

# Show the req/s value using figlet
figlet -c "Req/sec: $req_per_sec"

# Show the error count using figlet
figlet -c "Errors: $error_count" 

# Show the average latency using figlet
figlet -c "Avg Latency: $avg_latency"


