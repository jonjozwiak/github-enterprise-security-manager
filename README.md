# github-enterprise-security-manager

The code in this repository is used to facilitate adding users to the security manager role within many organizations in an enterprise.  It is a stop-gap solution until the enterprise-level security manager role is released.  

These scripts were written and tested on a Mac laptop.  I call that out because things like jq tend to have subtly different usage on linux.  GitHub CLI at the time was version 2.48.0.  

## Usage 

### Enterprise Owner 

1. Enterprise Owner must be an owner of every organization.  Go to your enterprise page and for each organization click the breadcrumbs and `join as an organization owner`
   https://github.com/enterprises/MY_ENTERPRISE/organizations
   If there is a way to automate this let me know.  I didn't see one.

2. Install pre-requisites ([GitHub CLI](https://cli.github.com/) and JQ)

    ```bash
    brew install gh jq
    ```

3. Login with the CLI and check for appropriate scopes

    ```bash
    gh auth login 
    gh auth status

    # You need admin:org and read:enterprise 

    # Add during login:
    # gh auth login --with-scopes admin:org,read:enterprise,admin:public_key,codespace,copilot,gist,repo,user

    # Refresh token with additional permissions:
    # gh auth refresh -s admin:org,read:enterprise,admin:public_key,codespace,copilot,gist,repo,user
    ```

4. Update the `sec-mgr-rollout.sh` script
    * `ENTERPRISE` should be set to your enterprise name
    * `USERS` should be a space separated list of users you want to invite to all organizations and give the security manager role to

5. Execute the script

    ```bash
    ./sec-mgr-rollout.sh
    ```

At this point each organization should have a team called `security-managers` that has the security-managers role.  Each person you added to the `USERS` variable should receive an organization invite for each organization and be added to the `security-managers` team.  Now it is up to the security managers to accept the invite.  

### Security Managers

Organization invites are good for 7 days.  If you have a small number of organizations you could just click the link in each e-mail.  However, you can also automate accepting an invite from every organization.  

1. Install the pre-requisites listed in step 2 for enterprise owners

2. Authenticate with the GitHub CLI as shows in step 3 for enterprise owners
    * Note you must have `members:write` permission.  I believe that comes as a standard member just running `gh auth login`

3. Execute the script

    ```bash
    ./sec-mgr-accept-invites.sh
    ```

At this point you should be a member of all organizations and have the `security-managers` role assigned to you from the `security-managers` team.  This gives you the permissions of a security manager as stated in [documentation](https://docs.github.com/en/organizations/managing-peoples-access-to-your-organization-with-roles/managing-security-managers-in-your-organization#permissions-for-the-security-manager-role). 
