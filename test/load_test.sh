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

# Execute the wrk command
wrk -t02 -c200 -d120s "http://haproxy-lb-1563643291.eu-central-1.elb.amazonaws.com" -s wrk.lua

# Script ends here
