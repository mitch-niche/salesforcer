#' Return the package's .state environment variable
#' 
#' @note This function is meant to be used internally. Only use when debugging.
#' @keywords internal
#' @export
salesforcer_state <- function(){
  .state
}

#' Write a CSV file in format acceptable to Salesforce APIs
#' 
#' @importFrom readr write_csv
#' @note This function is meant to be used internally. Only use when debugging.
#' @keywords internal
#' @export
sf_write_csv <- function(x, path){
  write_csv(x=x, path=path, na="#N/A")
}

#' Determine the host operating system
#' 
#' This function determines whether the system running the R code
#' is Windows, Mac, or Linux
#'
#' @return A character string
#' @examples
#' \dontrun{
#' get_os()
#' }
#' @seealso \url{http://conjugateprior.org/2015/06/identifying-the-os-from-r}
#' @note This function is meant to be used internally. Only use when debugging.
#' @keywords internal
#' @export
get_os <- function(){
  sysinf <- Sys.info()
  if (!is.null(sysinf)){
    os <- sysinf['sysname']
    if (os == 'Darwin'){
      os <- "osx"
    }
  } else {
    os <- .Platform$OS.type
    if (grepl("^darwin", R.version$os)){
      os <- "osx"
    }
    if (grepl("linux-gnu", R.version$os)){
      os <- "linux"
    }
  }
  unname(tolower(os))
}

#' Validate the input for an operation
#' 
#' @note This function is meant to be used internally. Only use when debugging.
#' @keywords internal
#' @export
sf_input_data_validation <- function(input_data, operation=''){
  
  # TODO:  Automatic date validation
  # https://developer.salesforce.com/docs/atlas.en-us.api_bulk_v2.meta/api_bulk_v2/datafiles_date_format.htm
  
  if(!is.data.frame(input_data)){
    if(is.null(names(input_data))){
      if(!is.list(input_data)){
        input_data <- as.data.frame(list(input_data), stringsAsFactors = FALSE)    
      } else {
        input_data <- as.data.frame(unlist(input_data), stringsAsFactors = FALSE)  
      }
    } else {
      input_data <- as.data.frame(as.list(input_data), stringsAsFactors = FALSE)  
    }
  }

  if(operation %in% c("describeSObjects") & ncol(input_data) == 1){
    names(input_data) <- "sObjectType"
  }
  
  if(operation %in% c("delete", "retrieve", "findDuplicatesByIds") & ncol(input_data) == 1){
    names(input_data) <- "Id"
  }
  
  if(operation %in% c("delete", "update", "findDuplicatesByIds")){
    if(any(grepl("^ID$|^IDS$", names(input_data), ignore.case=TRUE))){
      idx <- grep("^ID$|^IDS$", names(input_data), ignore.case=TRUE)
      names(input_data)[idx] <- "Id"
    }
    stopifnot("Id" %in% names(input_data))
  }
  
  return(input_data)
}

#' Download an Attachment
#' 
#' This function will allow you to download an attachment to disk based on the 
#' attachment body, file name, and path.
#' 
#' @importFrom httr content
#' @param body character; a URL path to the body of the attachment in Salesforce, typically 
#' retrieved via query on the Attachment object
#' @param name character; the name of the file you would like to save the content to
#' @param path character; a directory path where to create file, defaults to the current directory.
#' @examples 
#' \dontrun{
#' queried_attachments <- sf_query("SELECT Body, Name 
#'                                  FROM Attachment 
#'                                  WHERE ParentId = '0016A0000035mJ5'")
#' mapply(sf_download_attachment, queried_attachments$Body, queried_attachments$Name)
#' }
#' @export 
sf_download_attachment <- function(body, name, path = "."){
  resp <- rGET(sprintf("%s%s", salesforcer_state()$instance_url, body))
  f <- file.path(path, name)
  writeBin(content(resp, "raw"), f)
  return(invisible(file.exists(f)))
}

#' Remove NA Columns Created by Empty Related Entity Values
#' 
#' This function will detect if there are related entity columns coming back 
#' in the resultset and try to exclude an additional completely blank column 
#' created by records that don't have a relationship at all in that related entity.
#' 
#' @param dat data; a \code{tbl_df} or \code{data.frame} of a returned resultset
#' @template api_type
#' @importFrom dplyr select one_of
#' @keywords internal
#' @export
remove_empty_linked_object_cols <- function(dat, api_type = c("SOAP", "REST")){
  # try to remove references to empty linked entity objects
  # for example whenever a contact record isn't linked to an Account
  # then the record is included like this: <sf:Account xsi:nil="true"/>
  # which is very hard to discern if that is a Contact field called, "Account" that 
  # is NULL or it's a linked entity on an object called "Account" that is NULL. In 
  # our case we will try to remove if there are other fields in the result using that 
  # as a prefix to fields
  api_type <- match.arg(api_type)
  if(api_type == "REST"){
    # do nothing, typically fixed by itself
  } else if(api_type == "SOAP"){
    potential_object_prefixes <- grepl("^sf:[a-zA-Z]+\\.[a-zA-Z]+", names(dat))
    potential_object_prefixes <- names(dat)[potential_object_prefixes]
    potential_object_prefixes <- unique(gsub("(sf:)([a-zA-Z]+)\\.(.*)", "\\2", potential_object_prefixes))
    if(length(potential_object_prefixes) > 0){
      potential_null_object_fields_to_drop <- paste0("sf:", potential_object_prefixes)
      suppressWarnings(
        dat <- dat %>%
          # suppress the warning because it's possible that some of the 
          # columns are not actually in the data
          select(-one_of(potential_null_object_fields_to_drop))
      )
    }
  } else {
    stop("Unknown API type")
  }
  return(dat)
}

api_headers <- function(api_type=NULL, 
                        AllorNoneHeader=list(allOrNone=FALSE), 
                        AllowFieldTruncationHeader=list(allowFieldTruncation=FALSE), 
                        AssignmentRuleHeader=list(useDefaultRule=TRUE),
                        CallOptions=list(client=NA, defaultNamespace=NA), 
                        DisableFeedTrackingHeader=list(disableFeedTracking=FALSE), 
                        DuplicateRuleHeader=list(allowSave=FALSE, 
                                                 includeRecordDetails=FALSE, 
                                                 runAsCurrentUser=TRUE), 
                        EmailHeader=list(triggerAutoResponseEmail=FALSE, 
                                         triggerOtherEmail=FALSE, 
                                         triggerUserEmail=TRUE), 
                        LimitInfoHeader=list(current="20", 
                                             limit="250", 
                                             type="API REQUESTS"), 
                        LocaleOptions=list(language=NA), 
                        LoginScopeHeader=list(organizationId=NA, 
                                              portalId=NA), 
                        MruHeader=list(updateMru=FALSE), 
                        OwnerChangeOptions=list(options=list(list(execute=FALSE, 
                                                                  type="EnforceNewOwnerHasReadAccess"),
                                                             list(execute=TRUE, 
                                                                  type="KeepSalesTeam"),
                                                             list(execute=FALSE, 
                                                                  type="KeepSalesTeamGrantCurrentOwnerReadWriteAccess"),
                                                             list(execute=TRUE, 
                                                                  type="TransferOpenActivities"),
                                                             list(execute=FALSE, 
                                                                  type="TransferNotesAndAttachments"),
                                                             list(execute=TRUE, 
                                                                  type="TransferOtherOpenOpportunities"),
                                                             list(execute=TRUE, 
                                                                  type="TransferOwnedOpenOpportunities"),
                                                             list(execute=TRUE, 
                                                                  type="TransferContracts"),
                                                             list(execute=TRUE, 
                                                                  type="TransferOrders"),
                                                             list(execute=TRUE, 
                                                                  type="TransferContacts"))), 
                        PackageVersionHeader=list(packageVersions=NA), 
                        QueryOptions=list(batchSize=500), 
                        SessionHeader=list(sessionId=NA), 
                        UserTerritoryDeleteHeader=list(transferToUserId=NA), 
                        ContentTypeHeader=list(`Content-Type`="application/xml"), 
                        BatchRetryHeader=list(`Sforce-Disable-Batch-Retry`=FALSE), 
                        LineEndingHeader=list(`Sforce-Line-Ending`=NA), 
                        PKChunkingHeader=list(`Sforce-Enable-PKChunking`=FALSE)){
  
  # check if its in the supplied and known list
  # tailor the search to the API 
  
  api_type <- match.arg(api_type)
  
  if(!is.null()){
    if(api_type == "SOAP"){
      
    } else if(api_type == "REST"){
      
    } else if(api_type == "Bulk 1.0"){
      
    } else {
      # do nothing
    }
  }
    
  sf_user_info()$userLocale
  
  list()
}



# TESTING
# # if x is used, then it must be supplied or given a default
# # Error in zz() : argument "x" is missing, with no default
# zz <- function(x,y){
#   if(missing(x)){
#     x <- 2
#   }
#   xx <- x
#   return(5)
# }

