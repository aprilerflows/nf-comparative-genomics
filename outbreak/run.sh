#!/usr/bin/env bash
set -e

# 1) Install Miniconda (if 'conda' not on PATH)
if ! command -v conda &> /dev/null; then
  echo "🔄 Installing Miniconda..."
  curl -fsSL -o /tmp/Miniconda.sh \
    https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
  bash /tmp/Miniconda.sh -b -p $HOME/miniconda
  eval "$($HOME/miniconda/bin/conda shell.bash hook)"
  conda init
fi

# Refresh shell so `conda` is available
eval "$(conda shell.bash hook)"

# 2) Create the two environments from YAML
echo "📦 Creating Conda envs from envs/*.yml..."
conda env create -f envs/bactmap_env.yml   || echo "🟢 bactmap_env already exists"
conda env create -f envs/parsnp_env.yml    || echo "🟢 parsnp_env already exists"

# 3) Install Nextflow on the host if missing
if ! command -v nextflow &> /dev/null; then
  echo "🔨 Installing Nextflow..."
  curl -fsSL https://get.nextflow.io | bash
  sudo mv nextflow /usr/local/bin/
fi

# 4) Activate the bactmap_env so Nextflow runs under it
echo "🚀 Activating bactmap_env and launching pipeline..."
conda activate bactmap_env

# 5) Run Nextflow with Conda support
nextflow run . --all \
  --bactmap_csv   dummy/bactmap/samples.csv \
  --bactmap_ref   dummy/bactmap/ref.fa \
  --parsnp_ref    dummy/parsnp/ref.fa \
  --parsnp_dir    dummy/parsnp/assemblies \
  --with-conda \
  --no-historic

