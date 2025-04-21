mkdir -p dummy/bactmap dummy/parsnp/assemblies

# 1) BACTMAP dummy
cat > dummy/bactmap/samples.csv <<EOF
sample,fastq_r1,fastq_r2
A,A_R1.fq.gz,A_R2.fq.gz
EOF
touch dummy/bactmap/A_R1.fq.gz dummy/bactmap/A_R2.fq.gz
cat > dummy/bactmap/ref.fa <<EOF
>ref
ACTGACTGACTG
EOF

# 2) PARSNP dummy
cat > dummy/parsnp/ref.fa <<EOF
>ref
ACTGACTGACTG
EOF
# two assemblies
cat > dummy/parsnp/assemblies/A.fa <<EOF
>A
ACTGACTGACT1
EOF
cat > dummy/parsnp/assemblies/B.fa <<EOF
>B
ACTGACTGACT2
EOF

