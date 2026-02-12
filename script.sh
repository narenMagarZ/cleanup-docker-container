#!/bin/bash

# current date in sec
current_date=$(date +%s)

WINDOW_DAYS=30

is_dead_container_detected=0

while read -r id name; do

    container_created_date=$(docker inspect "$id" -f "{{.Created}}")
    # container_created_date in sec
    trimmed_date=${container_created_date%%.*}
    trimmed_date=${trimmed_date%Z}

    if date -d "$trimmed_date" +%s > /dev/null 2>&1; then
        estimated_date=$(date -d "$trimmed_date" +%s)
    else 
        estimated_date=$(date -j -f '%Y-%M-%dT%H:%M:%S' "$trimmed_date" +%s)
    fi

    # estimate days
    date_in_days=$(( (current_date - estimated_date) / 86400 ))

    if [ "$date_in_days" -gt "$WINDOW_DAYS" ]; then
        is_dead_container_detected=1
        echo "Removing container $id ($name)"
        docker rm -v "$id"
        echo "Removed..."
    fi
done < <(docker ps -a -f status=exited -f status=dead --format "{{.ID}} {{.Names}}")

if [ "$is_dead_container_detected" -eq 0 ] ; then
    echo "Nothing to remove!"
fi
