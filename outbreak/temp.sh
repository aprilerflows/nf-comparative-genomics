# Overwrite with 5kb reference & assemblies
rm -rf dummy/parsnp/ref.fa dummy/parsnp/assemblies
mkdir -p dummy/parsnp/assemblies

# 5 kb reference
{
  echo ">ref"
  tr -dc 'ACGT' < /dev/urandom | head -c 5000
  echo
} > dummy/parsnp/ref.fa

# Two 5 kb assemblies
for id in A B; do
  {
    echo ">${id}"
    tr -dc 'ACGT' < /dev/urandom | head -c 5000
    echo
  } > dummy/parsnp/assemblies/${id}.fa
done

# Verify sizes
wc -l dummy/parsnp/ref.fa
wc -l dummy/parsnp/assemblies/*.fa

