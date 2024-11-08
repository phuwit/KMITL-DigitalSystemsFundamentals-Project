#!/bin/bash

# Directory containing the PDF files
input_dir="$(pwd)"
output_dir="$(pwd)/converted"

# Create output directory if it doesn't exist
mkdir -p "$output_dir"

# Loop through all PDF files in the input directory
for pdf_file in "$input_dir"/*.pdf; do
  # Get the base name of the file (without extension)
  base_name=$(basename "$pdf_file" .pdf)

  # Convert PDF to plain SVG with "document cropped"
  inkscape "$pdf_file" --export-plain-svg="$output_dir/$base_name.svg" --export-area-drawing

  # Convert PDF to PNG with "document cropped"
  inkscape "$pdf_file" --export-png="$output_dir/$base_name.png" --export-area-drawing
done

echo "Conversion completed."
