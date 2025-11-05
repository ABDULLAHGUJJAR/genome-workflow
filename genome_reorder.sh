#!/bin/bash

# Step-by-step genome renaming + reordering + reversing workflow

# --- CONFIGURATION ---
INPUT_FASTA="11_scaffold.fasta"
RENAME_MAP="rename_map.tsv"
SPECIES_PREFIX="Clcutta4_"
ORDER_FILE="order.txt"
REVERSE_LIST="reverse_list.txt"

# Step 1: Rename scaffolds according to reference mapping
seqkit replace -p "^(.+)$" -r "{kv}" -k "$RENAME_MAP" "$INPUT_FASTA" > renamed_scaffold.fasta

# Step 2: Add species prefix to chromosome headers
sed "s/^>/>$SPECIES_PREFIX/" renamed_scaffold.fasta > "${SPECIES_PREFIX}renamed_scaffold.fasta"

# Step 3: Reorder chromosomes
> "${SPECIES_PREFIX}ordered.fasta"
while read -r chrom; do
    seqkit grep -r -p "$chrom" "${SPECIES_PREFIX}renamed_scaffold.fasta" >> "${SPECIES_PREFIX}ordered.fasta"
done < "$ORDER_FILE"

# Step 4: Reverse complement specific chromosomes
seqkit grep -r -f "$REVERSE_LIST" "${SPECIES_PREFIX}ordered.fasta" | seqkit seq -r -p -t dna > reversed_part.fasta
seqkit grep -r -v -f "$REVERSE_LIST" "${SPECIES_PREFIX}ordered.fasta" > forward_part.fasta

# Step 5: Merge back in correct order
> "${SPECIES_PREFIX}final.fasta"
while read -r chrom; do
    if grep -qx "$chrom" "$REVERSE_LIST"; then
        seqkit grep -r -p "$chrom" reversed_part.fasta >> "${SPECIES_PREFIX}final.fasta"
    else
        seqkit grep -r -p "$chrom" forward_part.fasta >> "${SPECIES_PREFIX}final.fasta"
    fi
done < "$ORDER_FILE"

# Step 6: Clean up temporary files (optional)
rm renamed_scaffold.fasta reversed_part.fasta forward_part.fasta

echo "✅ Done! Final FASTA: ${SPECIES_PREFIX}final.fasta"
