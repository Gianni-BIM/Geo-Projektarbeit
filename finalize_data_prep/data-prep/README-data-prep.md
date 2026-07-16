# Geo-Projektarbeit

## Setup

Install uv from [uv homepage](https://docs.astral.sh/uv/getting-started/installation/)

Clone the repository [github repository](https://github.com/Gianni-BIM/Geo-Projektarbeit)

Run `uv sync` to install project dependencies
Run `uv run nbstripout --install` to keep Jupyter notebooks clean in Git (i.e. remove outputs and execution metadata).

## Info

The repository uses .gitattributes to enforce consistent LF line endings across operating systems.

## Running in VS Code

### Data Processing Workflow
**Open the project in VS Code and select the project `.venv` interpreter if prompted.**

**AUTO RUN: If you see a file called a_auto_run_all_notebooks.ipynb, you can use it to run all following steps at once.**

**Step 1**: run data-prep/explore_indicator_data.ipynb --> several CSV-files used for inspection and transformation are produced in the output folder

**Step 2**: run data-prep/data_clean_and_transform.ipynb --> further CSV-files used for transformation and SHI calculation are produced in the output folder

**Step 3**: run data-prep/calculate_shi.ipynb --> SHI calculation is done

**Step 4**: run data-prep/additional_expl.ipynb
 --> preparation for pivot tables (Excel) to explore independent indicators, LC/LU reduction...
 --> OUTPUT: df_SHI_with_LC_LU_reduced.csv = dataset with 4538 points (suggestion for further usage with columns contained: SHI, hoehe_m, Landcover, Landuse)

 **Step 5** run data-prep/final_data_prep.ipynb --> further reduction of dataset

## Running jupyter lab

If you want to use jupyter lab to serve ipynb-files run: `uv run --with jupyter jupyter lab`.

If Jupyter Lab cannot find project dependencies, register the project's virtual environment as a Jupyter kernel:

`uv run python -m ipykernel install --user --name project-env --display-name "Project Environment"`

The kernel name can be chosen freely. This only needs to be done once per machine.

For further information [uv documentation jupyter lab](https://docs.astral.sh/uv/guides/integration/jupyter/#using-jupyter-within-a-project).

The **Data Processing Workflow** is the same as in VS Code (see above).
