param (
    [string]$Group,
    [string]$User,
    [string]$GroupDisplayName,
    [string]$UserDisplayName,
    [string]$UserEmail,
    [string]$Domain = "yourdomain.net",
    [switch]$GroupAll,
    [switch]$UserAll,
    [switch]$Members
)

# Usage:
# Get-Domain-Objects -Group "*GroupName*" -Members -Domain anotherdomain.net
# Get-Domain-Objects -Group
# Get-Domain-Objects -User -Members -Domain yourdomain.net
# Get-Domain-Objects -UserAll -Domain anotherdomain.net
# Get-Domain-Objects -GroupAll -Domain anotherdomain.net
# Get-Domain-Objects -UserDisplayName "*GroupName*" -Domain yourdomain.net
# Get-Domain-Objects -UserEmail "*email@*" -Domain yourdomain.net

# Function to search for groups
function SearchGroup {
    # Create a new directory search object
    $directorySearcher = New-Object System.DirectoryServices.DirectorySearcher

    # Set the search root to the root of the domain
    $directorySearcher.SearchRoot = [ADSI]"LDAP://$Domain"

    # Set the filter to search for group objects
    $directorySearcher.Filter = "(objectClass=group)"

    # If a specific group name is provided, adjust the filter
    if ($Group) {
        $directorySearcher.Filter = "(&(objectClass=group)(sAMAccountName=$Group))"
    } elseif ($GroupDisplayName) {
        $directorySearcher.Filter = "(&(objectClass=group)(displayName=$GroupDisplayName))"
    } elseif ($GroupAll) {
        $directorySearcher.Filter = "(objectClass=group)"
    }

    # Perform the search and retrieve the results
    $groups = $directorySearcher.FindAll()

    # Output the groups
    foreach ($group in $groups) {
        Write-Host "Group Name: $($group.Properties['sAMAccountName'])"
        Write-Host "Description: $($group.Properties['description'])"

        # Output members if the -Members switch is specified
        if ($Members) {
            # Get members of the group
            Write-Host "Members:"
            $memberDNs = $group.Properties['member']
            foreach ($memberDN in $memberDNs) {
                $user = ([ADSI]"LDAP://$memberDN").Properties
                Write-Host "User: $($user['sAMAccountName'])"
                Write-Host "Display Name: $($user['displayName'])"
                Write-Host "Email: $($user['mail'])"
                Write-Host ""
            }
        }

        Write-Host "-------------"
    }
}

# Function to search for users
function SearchUser {
    # Create a new directory search object
    $directorySearcher = New-Object System.DirectoryServices.DirectorySearcher

    # Set the search root to the root of the domain
    $directorySearcher.SearchRoot = [ADSI]"LDAP://$Domain"

    # Set the filter to search for user objects
    $directorySearcher.Filter = "(objectClass=user)"

    # If a specific user name is provided, adjust the filter
    if ($User) {
        $directorySearcher.Filter = "(&(objectClass=user)(sAMAccountName=$User))"
    } elseif ($UserDisplayName) {
        $directorySearcher.Filter = "(&(objectClass=user)(displayName=$UserDisplayName))"
    } elseif ($UserEmail) {
        $directorySearcher.Filter = "(&(objectClass=user)(mail=$UserEmail))"
    } elseif ($UserAll) {
        $directorySearcher.Filter = "(objectClass=user)"
    }

    # Perform the search and retrieve the results
    $users = $directorySearcher.FindAll()

    # Output the users
    foreach ($user in $users) {
        Write-Host "Username: $($user.Properties['sAMAccountName'])"
        Write-Host "Display Name: $($user.Properties['displayName'])"
        Write-Host "Email: $($user.Properties['mail'])"

        # Output groups the user belongs to
        if ($Members) {
            $memberOf = $user.Properties['memberOf']
            if ($memberOf) {
                Write-Host "Member Of:"
                foreach ($groupDN in $memberOf) {
                    $groupName = ([ADSI]"LDAP://$groupDN").Properties
                    Write-Host "Group Name: $($groupName['sAMAccountName'])"
                    Write-Host "Description: $($groupName['Description'])"
                }
            } else {
                Write-Host "Group '$groupName' is not a member of any group."
            }
        }

        Write-Host "-------------"
    }
}

# Check if -Group or -User argument is provided and call the respective function
if ($Group) {
    SearchGroup
} elseif ($GroupDisplayName) {
    SearchGroup
} elseif ($GroupAll) {
    SearchGroup
} elseif ($User) {
    SearchUser
} elseif ($UserDisplayName) {
    SearchUser
} elseif ($UserEmail) {
    SearchUser
} elseif ($UserAll) {
    SearchUser
} else {
    Write-Host "Please specify either -Group or -User or -GroupDisplayName or -UserDisplayName or -UserEmail or -GroupAll or -UserAll argument."
}
