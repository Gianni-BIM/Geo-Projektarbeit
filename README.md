# Geo-Projektarbeit

## Setup

Install uv from [uv homepage](https://docs.astral.sh/uv/getting-started/installation/)

Clone the repository [github repository](https://github.com/Gianni-BIM/Geo-Projektarbeit)

Run `uv sync` to install project dependencies
Run `uv run nbstripout --install` to keep Jupyter notebooks clean in Git (i.e. remove outputs and execution metadata).

## Info

The repository uses .gitattributes to enforce consistent LF line endings across operating systems.

## Running jupyter lab

If you want to use jupyter lab to serve ipynb-files run: `uv run --with jupyter jupyter lab`.
For further information [uv documentation jupyter lab](https://docs.astral.sh/uv/guides/integration/jupyter/#using-jupyter-within-a-project).

## Data Processing Workflow

**Step 1**: run data-prep/explore_indicator_data.ipynb --> several CSV-files used for inspection and transformation are produced in the output folder

**Step 2**: run data-prep/data_clean_and_transform.ipynb --> further CSV-files used for transformation and SHI calculation are produced in the output folder

**Step 3**: run data-prep/calculate_shi.ipynb --> SHI calculation is done

**Step 4**: run data-prep/additional_expl.ipynb
 --> preparation for pivot tables (Excel) to explore independent indicators, LC/LU reduction...
 --> OUTPUT: df_SHI_with_LC_LU_reduced.csv = dataset with 4538 points (suggestion for further usage with columns contained: SHI, hoehe_m, Landcover, Landuse)

