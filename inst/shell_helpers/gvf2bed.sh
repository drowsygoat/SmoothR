#!/bin/bash

# Check if the correct number of arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <input.gvf(.gz)> <output.bed>"
    exit 1
fi

input_file="$1"
output_file="$2"

# Function to convert GVF to BED
convert_gvf_to_bed() {
    awk '
    BEGIN {
        FS = "\t";  # Set field separator to tab
        OFS = "\t"; # Set output field separator to tab
    }
    # Skip header lines (lines that start with "##")
    /^##/ { next }

    # Process lines that contain data (non-header lines)
    {
        # Extract fields
        chrom = $1;
        start = $4 - 1;  # BED is 0-based, so subtract 1 from the start position
        end = $5;        # End position
        name = $9;       # The attributes column
        score = ".";     # BED score, using "." for simplicity (optional)
        strand = $7;     # Strand information

        # Extract ID or other identifier from the attributes column
        split(name, attrs, ";");
        for (i in attrs) {
            split(attrs[i], kv, "=");
            if (kv[1] == "ID") {
                name = kv[2];
                break;
            }
        }

        # Print to BED format
        print chrom, start, end, name, score, strand;
    }
    ' "$1" > "$2"
}

# Check if the input file is compressed
if [[ "$input_file" == *.gz ]]; then
    echo "Input file is compressed. Processing..."
    # Decompress the input file and pipe it to the conversion function
    gunzip -c "$input_file" | convert_gvf_to_bed /dev/stdin "$output_file"
else
    echo "Input file is not compressed. Processing..."
    # Process the uncompressed file
    convert_gvf_to_bed "$input_file" "$output_file"
fi

echo "Conversion completed. Output saved to $output_file"