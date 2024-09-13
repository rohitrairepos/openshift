#!/bin/bash

# Script Description:
# This script processes Kubernetes cluster role bindings to extract and display details.
# It retrieves information about each cluster role binding, including Kind, Name, Role, RoleBinding, and Namespace.
# The script displays a progress bar to indicate the status of processing.
# After processing all role bindings, it sorts and displays the results in a tabular format.
#
# How to Use:
# 1. Ensure you have `oc` (OpenShift CLI) installed and configured to access your cluster.
# 2. Save this script to a file, e.g., `process_role_bindings.sh`.
# 3. Make the script executable: `chmod +x process_role_bindings.sh`
# 4. Run the script: `./process_role_bindings.sh`



# Function to print progress
print_progress() {
  local progress=$1
  local total=$2
  local percent=$(( progress * 100 / total ))
  local bar_length=50
  local bar=$(printf "%-${bar_length}s" "#" | tr ' ' '#')

  printf "\r[%-${bar_length}s] %d%%" "${bar:0:(percent * bar_length / 100)}" "$percent"
}

# Get the total count of cluster role bindings
total_count=$(oc get clusterrolebinding --no-headers | wc -l)
current_count=0

# Print initial message
echo "Starting the processing of cluster role bindings. This may take a few moments..."


# Collect and process results
results=$(mktemp)

for i in $(oc get clusterrolebinding -o name); do
  oc describe $i | awk '
  /User|Group|ServiceAccount/ {subject=$1; name=$2; namespace=$3; next}
  /Kind:/ {kind=$2}
  /^Name:/ {role_name=$2}
  END {
    if (kind && role_name) {
      if (subject && name) {
        printf "%-20s %-70s %-20s %-80s %-20s\n", kind, name, subject, role_name, namespace
      } else {
        printf "%-20s %-70s %-20s %-80s %-20s\n", kind, "", "", role_name, namespace
      }
    }
  }' >> "$results"

  # Update progress
  ((current_count++))
  print_progress "$current_count" "$total_count"
done

# Print newline for progress bar
printf "\n"

# Print final message
echo "Processing complete. Sorting and displaying the results..."


# Print headings
printf "%-20s %-70s %-20s %-80s %-20s\n" "Kind" "Name" "Role" "RoleBinding" "Namespace"

# Sort and print results
sort -k2 "$results"

# Clean up
rm "$results"
