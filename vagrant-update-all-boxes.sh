#!/bin/bash

OLDIFS=$IFS
export IFS=$'\n'

# Find all boxes which have updates
AVAILABLE_UPDATES=$(vagrant box outdated --global | grep outdated | tr -d "*'" | cut -d ' ' -f 2 2>/dev/null)

if [[ ${#AVAILABLE_UPDATES[@]} -ne 0 ]]; then

    for box in ${AVAILABLE_UPDATES}; do

        echo "Found an update for ${box}"

        # Find all current versions
        boxinfo=$(vagrant box list | grep ${box})

        for boxtype in ${boxinfo}; do

            provider=$(echo ${boxtype} | awk -F\( '{print $2}' | awk -F\, '{print $1}')
            version=$(echo ${boxtype} | cut -d ',' -f 2 | tr -d ' )')

            # Add latest version
            vagrant box add --clean ${box} --provider ${provider}
            BOX_UPDATED="TRUE"

        done

    done

echo "All boxes are now up to date! Pruning..."

# Remove all old versions
vagrant box prune -f

else
    echo "All boxes are already up to date!"
fi

vagrant box outdated --global

export IFS=$OLDIFS
