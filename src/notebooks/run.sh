#!/bin/bash


if [[ "$run_interactively" == "true" ]]; then
  jupyter lab --allow-root --ip='*' --NotebookApp.token='' --NotebookApp.password=''
else
  jupyter nbconvert --to script /veld/code/analyse_embeddings.ipynb
  python3 /veld/code/analyse_embeddings.py
  rm /veld/code/analyse_embeddings.py
fi

