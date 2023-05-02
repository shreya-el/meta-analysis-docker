library("mapGCT")

updateGCT <- function(dataset_id, source_csv_dir = "source_csv"){
    gct_obj <- parse_gct(paste0(dataset_id, ".gct"))
    matrix <- gct_obj@mat
    coldata <- gct_obj@cdesc

    curated_info <- read.csv(paste0(source_csv_dir, "/", dataset_id, ".csv"))
    colnames(curated_info) <- paste("source", colnames(curated_info), sep = "_")

    factor_columns <- sapply(curated_info, is.factor)  
    curated_info[factor_columns] <- lapply(curated_info[factor_columns], as.character)
    coldata = merge(curated_info, coldata, by.x = "source_cid", by.y = "id")
    rownames(coldata) = coldata$source_cid

    gctObj <- mapGCT::to_GCT(gct_obj@mat, cdesc = coldata, rdesc = gct_obj@rdesc)
    write_gct(gctObj, paste0(dataset_id, ".gct"))   
}

args = commandArgs(trailingOnly=TRUE)
dataset_id <- args[1]
updateGCT(dataset_id)