#!/usr/bin/env bash

set -u

file_name="contribution.txt"
date_file="date.txt"
branch="main"

if [[ ! -f "$date_file" ]]; then
    echo "Error: $date_file not found."
    exit 1
fi

while IFS= read -r date || [[ -n "$date" ]]; do
    # Skip empty lines
    [[ -z "$date" ]] && continue

    # Remove possible carriage return
    date="${date%$'\r'}"

    commit_date="${date}T12:00:00"

    echo "Processing commit for date: ${commit_date}"

    # Append contribution
    echo "Commit on ${commit_date}" >> "$file_name"

    # Stage changes
    git add "$file_name"

    # Create backdated commit
    if ! GIT_AUTHOR_DATE="$commit_date" \
         GIT_COMMITTER_DATE="$commit_date" \
         git commit -m "Commit on ${commit_date}"; then
        echo "Commit failed for ${commit_date}."
        exit 1
    fi

    # Push to GitHub
    if git push origin "$branch"; then
        echo "Successfully committed and pushed: ${commit_date}"

        # Remove processed date (GNU sed / Arch Linux)
        sed -i "\|^${date//|/\\|}$|d" "$date_file"

        echo "Removed ${date} from ${date_file}."
    else
        echo "Push failed for ${commit_date}."
        echo "Date remains in ${date_file}."
        exit 1
    fi

done < "$date_file"

echo "Script finished."