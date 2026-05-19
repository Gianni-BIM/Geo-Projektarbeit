# Geo-Projektarbeit

## Setup

Install uv from [uv homepage](https://docs.astral.sh/uv/getting-started/installation/)

Clone the repository [github repository](https://github.com/Gianni-BIM/Geo-Projektarbeit)

Run `uv sync` to install project dependencies


## Running jupyter lab

If you want to use jupyter lab to serve ipynb-files run: `uv run --with jupyter jupyter lab`.
For further information [uv documentation jupyter lab](https://docs.astral.sh/uv/guides/integration/jupyter/#using-jupyter-within-a-project).

## Data Processing Workflow

**Step 1**: run data-prep/data_preparation.ipynb --> several CSV-files with results are produced in the output folder

**Step 2**: run data-prep/data_exploration.ipynb --> a data_exploation_summary.txt is produced in the output folder


