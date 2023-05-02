#!/bin/sh

###### ==========================================
######  Title:  Entry point for Component Run
######  Author: Nishu Nehra
######  Date:   3 Feb 2023
###### ==========================================

echo "=================================== LOGING-IN TO POLLY ======================================="
polly login --auto
echo "================================== POLLY LOGIN SUCCESS =======================================\n\n"

# TODO Add a basic checkParameters script Eg https://github.com/PF2-pasteur-fr/SARTools/blob/master/R/checkParameters.DESeq2.r
# echo "=============================== GIT CLONING $METHOD BRANCH ==================================="
# READ_ONLY_TOKEN_D=$(cat READ.key)
# READ_ONLY_TOKEN=$(echo $READ_ONLY_TOKEN_D | openssl aes-256-cbc -d -a -pbkdf2 -pass pass:somepassword)
# git clone --single-branch --branch $METHOD-prod https://x-token-auth:${READ_ONLY_TOKEN}@bitbucket.org/elucidatainc/${REPOSITORY}.git
# cp -r ${REPOSITORY}/* ./
# echo "================================== GIT CLONING SUCCESS =======================================\n\n"

# mkdir results
# mkdir params

echo "=================================== CONFIGURING JOBS ========================================="

# For GDX and GSEA like components
polly files copy  -d ./cohort.csv -s polly://${COHORT_CSV_PATH} --workspace-id ${POLLY_WORKSPACE_ID}
polly files copy  -d ./datasets.csv -s polly://${DATASET_CSV_PATH} --workspace-id ${POLLY_WORKSPACE_ID}
polly files sync  -d ./source_csv -s polly://${SOURCE_CSV_PATH} --workspace-id ${POLLY_WORKSPACE_ID}
python3 component_GNU_generator.py

# To overwrite certain Datasets
parallel --delay 1 -j 100 < updateGCTsParallel.sh
polly files sync -d ./ -s polly://${DEP_DIR} --workspace-id ${POLLY_WORKSPACE_ID}
echo "=============================== CONFIGURING JOBS SUCCESS =====================================\n\n"


echo "==================================== EXECUTING JOBS =========================================="
parallel --delay 1 -j 100 < parallel.sh
echo "================================= EXECUTING JOBS SUCCESS ====================================="


echo "==================================== SYNC RESULTS TO POLLY - STARTING =========================================="
polly files sync -s results -d polly://${RESULTS_DIR} --workspace-id ${POLLY_WORKSPACE_ID}
echo "================================= SYNC RESULTS TO POLLY - SUCCESS ====================================="