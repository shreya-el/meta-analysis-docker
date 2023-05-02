###### ==========================================
######  Title:  Entry point for Component Run
######  Author: Nishu Nehra
######  Date:   3 Feb 2023
###### ==========================================

import os
from polly.omixatlas import OmixAtlas
from polly.auth import Polly
import json
import pandas as pd
from os.path import exists

# TODO Update download function to skip dowload credits Eg phantasus
REFRESH_TOKEN = os.getenv("POLLY_REFRESH_TOKEN")
omix_atlas =  OmixAtlas(REFRESH_TOKEN, env = "polly")


def downloadDataset(dataset_id):
    """
        To download data from OmixAtlas

        :param - dataset_id: Dataset to download
        :return - downloads dataset to a dir mentioned
    """
    repo_key = os.environ["SOURCE_OMIXATLAS"]
    file_name = f"{dataset_id}.gct"
    try:
        omix_atlas.download_metadata(str(repo_key), dataset_id, file_path = "./")
        api_response = omix_atlas.download_data(int(repo_key), dataset_id).get("data")
        url = api_response["attributes"]["download_url"]
        os.system(f"wget -O '{file_name}' '{url}' >/dev/null 2>&1")
        print(f"Downloaded file at {file_name}")
        return True
    except:
        print("Some error occured in dataset sync from Omix-Atlas")
        return True


def generateProcessingScriptFor2Gen(csv_file_path = "./cohort.csv", params_dir = "./params/"):
    import csv
    from os.path import exists
    if (exists(csv_file_path)):
        with open(csv_file_path, encoding = 'utf-8') as csv_file_handler:
            csv_reader = csv.DictReader(csv_file_handler)
            sh_object = open("parallel.sh", "w")
            for rows in csv_reader:
                file_name = fileNameGenerator()
                with open(params_dir + file_name + ".json", 'w', encoding = 'utf-8') as json_file_handler:
                    json_file_handler.write(json.dumps(rows, indent = 4))
                dataset_id = rows["dataset_id"]
                status = downloadDataset(dataset_id)
                if status:
                    sh_object.write(f"Rscript --vanilla run.R {dataset_id} {file_name}\n")
                else:
                    print(f"Something went wrong while downloading dataset {rows['dataset_id']}")
            sh_object.close()
    else:
        print(f"Could not find the cohort.csv file")
        
def fileNameGenerator():
    import random
    file_name = "".join(random.choices('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ', k = 10))
    return file_name

def generateProcessingScript(datasets):
    """
        To generate processing script for each dataset    
    """

    sh_object = open("parallel.sh", "w")
    for dataset in datasets:
        status = downloadDataset(dataset)
        if status:
            sh_object.write(f"Rscript --vanilla run.R {dataset}\n")
        else:
            print(f"Something went wrong while downloading dataset {dataset}")
    sh_object.close()

def getDatasets():
    dataset_file_path = "datasets.csv"
    if (exists(dataset_file_path)):
        try:
            dataset_df = pd.read_csv(dataset_file_path)
            if "dataset_id" in dataset_df.columns.to_list():
                dataset_list = dataset_df["dataset_id"].to_list()
            else:
                print(f"'dataset_id' column is not present in {dataset_file_path}")
                dataset_list = None
        except:
            print(f"File {dataset_file_path} is not valid")
            dataset_list = None
            
    else:
        dataset_list = os.getenv("DATASETS")
        if isinstance(dataset_list, str): 
            dataset_list = (
                dataset_list.replace("[", "").replace("]", "").replace("'", "").replace(" ", "").split(",")
            )
        else:
            dataset_list = None 
    return(dataset_list)

def generateUpdateGCTsScript(datasets):
    source_csv_dir = "source_csv"
    sh_object = open("updateGCTsParallel.sh", "w")
    datasets = list(set(datasets))
    for dataset in datasets:
        dataset_source_csv_path = source_csv_dir + "/" + dataset + ".csv"
        if (exists(dataset_source_csv_path)):
            sh_object.write(f"Rscript --vanilla updateGCTs.R {dataset}\n")
        else:
            print(f"Source CSV is not present for dataset {dataset}")
    sh_object.close()

def main():
    method = os.getenv("METHOD")
    datasets = getDatasets()
    generateUpdateGCTsScript(datasets)
    if (not isinstance(method, type(None))) and (method in ['gdx', 'gdx-csv']):
        generateProcessingScriptFor2Gen()
    elif (not isinstance(datasets, type(None))) and isinstance(datasets, list):
        generateProcessingScript(datasets) 

if __name__ == "__main__":
    main()
