#!/bin/bash
#
# This script is used by an enterprise owner to create security manager teams in all organizations in the enterprise
# The enterprise owner MUST already be an organization owner for every organization
# This needs to be done manually in the UI:
# https://github.com/enterprises/MY_ENTERPRISE/organizations

# This script assumes that you have SSO at the enterprise level
# and that the users are already part of the enterprise
# It also manually creates teams rather than using team sync from IdP

# Variables - Update these for the enterprise and users to deploy
ENTERPRISE="octodemo"   # The name of the enterprise
USERS="writingpanda"    # The users to add to orgs and security manager teams (space separated list)
#USERS="user1 user2 user3 user4"


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

# Authenticate with GitHub CLI
# Note: This assumes that you have already authenticated your GitHub CLI.
# If not, you need to do so manually by running 'gh auth login'

# List all organizations in the Octodemo enterprise
orgs=$(gh api graphql -f query='
    query($enterprise: String!, $endCursor: String) {
        enterprise(slug: $enterprise) {
            organizations(first: 100, after: $endCursor) {
                nodes {
                    login
                }
                pageInfo {
                    endCursor
                    hasNextPage
                }
            }
        }
    }
' -f enterprise=octodemo --paginate  | jq -r '.data.enterprise.organizations.nodes[].login')

# For each organization, add a team called "security-managers"
for org in $orgs
do
    echo "** Organization: $org"

    # Check if the user can administer the organization (verify org admin rights)
    can_administer=$(gh api graphql -f query='
        query($login: String!) {
            organization(login: $login) {
                viewerCanAdminister
            }
        }
        ' -f login=$org | jq -r '.data.organization.viewerCanAdminister')

    # If the user cannot administer the organization, print an error message
    if [[ $can_administer == "false" ]]; then
        echo "    - Error: You do not have administration rights for the organization $org"
        echo ""
    else
        # Check if the team already exists
        # https://docs.github.com/rest/teams/teams#get-a-team-by-name
        team=$(gh api -X GET /orgs/$org/teams/security-managers 2> /dev/null)

        # If the team does not exist, create it
        if [[ $team == *"Not Found"* ]]; then
            echo "   - Creating team 'security-managers'"
            gh api -X POST /orgs/$org/teams -F name="security-managers"
        else
            echo "   - Team 'security-managers' already exists"
        fi

        # Add security manager team if it doesn't exist
        # https://docs.github.com/en/rest/orgs/security-managers?apiVersion=2022-11-28#list-security-manager-teams
        securitymanagers=$(gh api -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" /orgs/$org/security-managers)
        if [[ $team == *"Not Found"* ]]; then
            gh api -X PUT -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" /orgs/$org/security-managers/teams/security-managers
        else
            team_slug=$(echo "$securitymanagers" | jq -r '.[].slug')
            # Check if the 'security-managers' team is in the list
            if [[ $securitymanagers != *"security-managers"* ]]; then
                # If the 'security-managers' team is not in the list, add it
                #https://docs.github.com/en/rest/orgs/security-managers?apiVersion=2022-11-28#add-a-security-manager-team
                echo "   - Adding team 'security-managers' as a security manager team"
                gh api -X PUT -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" /orgs/$org/security-managers/teams/security-managers
            else
                echo "   - Team 'security-managers' is already a security manager team"
            fi
        fi

        # Invite a user to the organization
        for user in $USERS; do
            # Not needed - team membership add will send member invite...
            # Check if the user is already a member of the organization
            # https://docs.github.com/en/rest/orgs/members?apiVersion=2022-11-28#get-organization-membership-for-a-user
            #membership=$(gh api -X GET /orgs/$org/memberships/$user 2> /dev/null)

            # If the user is not a member of the organization, invite them
            # https://docs.github.com/rest/orgs/members#add-an-organization-member
            #if [[ $membership == *"Not Found"* ]]; then
            #    echo "   - Inviting user '$user' to the organization"
            #    gh api -X PUT /orgs/$org/memberships/$user -F role=member
            #else
            #    echo "   - User '$user' is already a member of the organization"
            #fi
                # Note user has 7 days to click to the link in their email to join
                

            # Check if the user is already a member of the team
            # https://docs.github.com/en/rest/teams/members?apiVersion=2022-11-28#get-team-membership-for-a-user
            team_membership=$(gh api -X GET /orgs/$org/teams/security-managers/memberships/$user 2> /dev/null)
            if [[ $team_membership == *"Not Found"* ]]; then
                # If the user is not a member of the team, add them
                # https://docs.github.com/rest/teams/members#add-or-update-team-membership-for-a-user
                echo "   - Adding user '$user' to the team 'security-managers'"
                gh api -X PUT /orgs/$org/teams/security-managers/memberships/$user -F role=member
            else
                echo "   - User '$user' is already a member of the team 'security-managers'"
            fi
        done

        echo ""
    fi
done
