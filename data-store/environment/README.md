# Environment Variable Configuration

Environment variable configuration files to be used when deploying
[cgp-data-store](https://github.com/DataBiosphere/cgp-data-store).


## Use
1. Clone [cgp-data-store](https://github.com/DataBiosphere/cgp-data-store)
2. Copy the environment* files in this directory, to the top-level directory
of the `cgp-data-store` clone above.
3. Review copied files for any additional modifications for the specific
deployment about to be performed. In general, these fields should be changed in the `*.local` file.
Fields that typically require customization include:

    * PROJECT - lower-case name of associated grant or, for personal deployments, your UCSC login name
    * STAGE - typically `dev`, `staging` or `prod`
    * AWS_PROFILE
    * API_DOMAIN_NAME
    * DSS_SUBSCRIPTION_AUTHORIZED_DOMAINS_TEST

4. Run: `source environment`
5. (for staging deployment) Run: `source environment.staging`

## Maintenance
1. Periodically compare the files in this directory to currently used version of
[cgp-data-store](https://github.com/DataBiosphere/cgp-data-store)
(and [HumanCellAtlas/data-store](https://github.com/HumanCellAtlas/data-store))
and incorporate changes as appropriate to update the files in this directory.

