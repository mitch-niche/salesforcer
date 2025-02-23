## salesforcer 0.1.2.9000

### Features

  * Add **RForcecom** backward compatibile version of `rforcecom.getObjectDescription()`
  * Add `sf_describe_object_fields()` which is a tidyier version of `rforcecom.getObjectDescription()`
  * Allow users to control whether query results are kept as all character or the 
  types are guessed (#12)
  * Add `sf_get_all_jobs_bulk()` so that users can see retrieve details for all 
  bulk jobs (#13)
  * Add new utility functions `sf_set_password()` and `sf_reset_password()` (#11)
  * Add two new functions to check for duplicates (`sf_find_duplicates()`, `sf_find_duplicates_by_id()`) (#4)
  * Add new function to download attachments to disk (`sf_download_attachment()`) (#20)
  
### Bug Fixes

  * Fix bug where Username/Password authenticated sessions where not working with 
  api_type = "Bulk 1.0"
  * Fix bug where Bulk 1.0 queries that timeout hit an error while trying to abort 
  since that only supported aborting Bulk 2.0 jobs (#13)
  * Fix bug that had only production environment logins possible because of hard 
  coding (@weckstm, #18)
  * Make `sf_describe_object_fields()` more robust against nested list elements (#16)
  
---
  
## salesforcer 0.1.2 [release](https://github.com/StevenMMortimer/salesforcer/releases/tag/v0.1.2)

### Features

  * Add support for Bulk 1.0 operations of "create", "update", "upsert", "delete" and "hardDelete"
  * Bulk 2.0 operations, by default, now return a single `tbl_df` containing all 
  of the successful records, error records, and unprocessed records
  * Created internal functions that explicity call each API for an operation. For 
  example, `sf_create()` routes into `sf_create_soap()`, `sf_create_rest()`, and 
  `sf_bulk_operation()`.

---

## salesforcer 0.1.1 [release](https://github.com/StevenMMortimer/salesforcer/releases/tag/v0.1.1)

### Features

  * Add `sf_search()` with REST and SOAP API support for SOSL and free text search
  * Add `sf_describe_objects()` with REST and SOAP API to return object metadata
  * Add REST API support for upsert (`sf_upsert()`)
  * Add SOAP API support for the following operations:
    * `sf_create()`
    * `sf_update()`
    * `sf_delete()`
    * `sf_retrieve()`
  * Add Metadata API support for the following operations:
    * `sf_create_metadata()`
    * `sf_read_metadata()`
    * `sf_update_metadata()`
    * `sf_upsert_metadata()`
    * `sf_delete_metadata()`
    * `sf_describe_metadata()`
    * `sf_list_metadata()`
    * `sf_rename_metadata()`
    * `sf_retrieve_metdata()`
    * `sf_deploy_metdata()`
  * Make the default file name for a cached token `.httr-oauth-salesforcer` so that 
  it does not clash with other package token names

### Bug Fixes

  * `sf_user_info()` returning `argument is of length zero` because token is not 
automatically refreshed before calling GET

  * `sf_token()` ignoring basic auth'ed sessions since it was only looking for a token 
using `token_avaiable()`. Replace with `sf_auth_check()` so now it considers a 
session or a token to be "available" (#1).

---

## salesforcer 0.1.0 [release](https://github.com/StevenMMortimer/salesforcer/releases/tag/v0.1.0)

### Features

  * OAuth 2.0 and Basic authentication methods (`sf_auth()`)
  * Query operations via REST and Bulk APIs (`sf_query()`)
  * CRUD operations (Create, Retrieve, Update, Delete) for REST and Bulk APIs: 
    * `sf_create()`
    * `sf_retrieve()`
    * `sf_update()` 
    * `sf_upsert()`
    * `sf_delete()`
  * Backwards compatibile versions of **RForcecom** package functions:
    * `rforcecom.login()` 
    * `rforcecom.getServerTimestamp()`
    * `rforcecom.query()`
    * `rforcecom.bulkQuery()`
    * `rforcecom.create()`
    * `rforcecom.update()`
    * `rforcecom.upsert()`
    * `rforcecom.delete()`
  * Basic utility calls: 
    * `sf_user_info()`
    * `sf_server_timestamp()`
    * `sf_list_rest_api_versions()`
    * `sf_list_resources()`
    * `sf_list_api_limits()`
    * `sf_list_objects()`
