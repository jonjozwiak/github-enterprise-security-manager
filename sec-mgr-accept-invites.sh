#!/bin/bash
# 
# This script is used by a security manager to accept invites to join organizations

# Check if gh is installed
if ! command -v gh &> /dev/null
then
        echo "GitHub CLI could not be found"
        exit
fi

# Check if jq is installed
if ! command -v jq &> /dev/null
then
        echo "jq could not be found"
        exit
fi

# List all of my organization memberships that are pending
# https://docs.github.com/en/rest/orgs/members?apiVersion=2022-11-28#list-organization-memberships-for-the-authenticated-user
pending_invites=$(gh api -X GET /user/memberships/orgs --paginate 2> /dev/null | jq -r '.[] | select(.state == "pending") | .organization.login')

# If there are no pending invites, exit
if [[ -z $pending_invites ]]; then
    echo "No pending invites"
    exit 0
fi

# Loop through each pending invite
for org in $pending_invites; do
    echo "Accepting invite to join organization '$org'"
    # Accept the invite
    # https://docs.github.com/en/rest/orgs/members?apiVersion=2022-11-28#update-an-organization-membership-for-the-authenticated-user
    gh api -X PATCH -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" /user/memberships/orgs/$org -f "state=active"
done

