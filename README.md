# Geo-Projektarbeit

## Setup

Install uv from [uv homepage](https://docs.astral.sh/uv/getting-started/installation/)

Clone the repository [github repository](https://github.com/Gianni-BIM/Geo-Projektarbeit)

Run `uv sync` to install project dependencies


## Running jupyter lab

If you want to use jupyter lab to serve ipynb-files run: `uv run --with jupyter jupyter lab`.
For further information [uv documentation jupyter lab](https://docs.astral.sh/uv/guides/integration/jupyter/#using-jupyter-within-a-project).

## Data Processing Workflow

**Step 1**: run data-prep/explore_indicator_data.ipynb --> several CSV-files used for inspection and transformation are produced in the output folder

**Step 2**: run data-prep/data_clean_and_transform.ipynb --> further CSV-files used for transformation and SHI calculation are produced in the output folder
+ Note: many of these CSV-files can be considered as "cleaning or calculation steps on the way to SHI"

**Step 3**: run data-prep/calculate_shi.ipynb --> SHI calculation is done


