#!/usr/bin/env bash

# ./jq-skills.sh
# http://www.compciv.org/recipes/cli/jq-for-parsing-json/

# https://cameronnokes.com/blog/jq-cheatsheet/
# Downloads the latest APOD and saves to a file
if [[ -f "apod.png" ]]; then  # variable found:
   echo "Reusing apod.png"
else
   echo "Downloading apod.png (a hi-res color photo of the moon) ..."
   # Uses the -r (raw) command when saving the output to a variable to get rid of formatting like quotes and spaces for single values. 
   url="https://api.nasa.gov/planetary/apod?api_key=DEMO_KEY"
   curl -o apod.png "$(curl -s $url | jq -r '.hdurl')"
fi

set -x

echo ">>> In a folder containing a package.json file:"
jq '.name' package.json
   # Returns the name such as "@jupyterlab/application-top"

echo ">>> Gets the total number of dependencies in a package.json file: 67"
jq -r '[(.dependencies, .devDependencies) | keys] | flatten | length' package.json

echo ">> Join elements of an array using a separator: # Cameron Nokes"
echo '{ "firstName": "Cameron", "lastName": "Nokes" }' | jq '[.firstName, .lastName] | join(" ")'

echo ">>> Get a named property; 1"
echo '{"id": 1, "name": "Cam"}' | jq '.id'``
 
echo ">>> Get a named property; 1  : 42"
echo '{"nested": {"a": {"b": 42}}}' | jq '.nested.a.b'

echo ">>> Gets an array of unique values: [1, 2, 3]"
echo '[1, 2, 2, 3]' | jq 'unique'
 

echo ">>> "
# Inspect a big unknown blob of JSON.
# The following command grabs a JSON blob that represents the open issues in the public Docker GitHub repository, and store it in a shell variable named foo:
if [[ -z "${foo}" ]]; then  # variable found:
   echo "Reusing \$foo"
else
   echo "Downloading..."
   # From https://blog.appoptics.com/jq-json/ by https://twitter.com/librato
   foo=$(curl 'https://gist.githubusercontent.com/djosephsen/a1a290366b569c5b98e9/raw/c0d01a18e16ba7c75d31a9893dd7fa1b8486a963/docker_issues')
fi
# echo "/n zzz"

echo ">>> Notice the file begins with "[" (defining an array):"
echo '[]{}' | jq type
	# "array" and "object"



echo ">>> comma separate multiple items: { \"a\": 2, \"b\": 1 }"
echo '{ "a": 1, "b": 2 }' | jq '{ a: .b, b: .a }'

echo ">>> Gets an object’s keys as an array: [a, b]"
echo '{ "a": 1, "b": 2 }' | jq 'keys'

echo ">>> Get an array element’s property: # Luigi"
echo '[{"id": 1, "name": "Mario"}, {"id": 2, "name": "Luigi"}]' | jq '.[1].name'



echo ">>> List count of objects: # 30"
echo ${foo} | jq length  

echo ">>> List type and count of objects: array,30"
echo ${foo} | jq '.|type,length'

echo ">>> Unwrap layer of the input. I think of them as ‘unwrappy brackets’ when I see them in jq:"
echo ${foo} | jq '.[]' | more
   # Using more to show only first set of lines:
   # { 
   #   "url": "https://api.github.com/repos/docker/docker/issues/18048",
   # ...
   # Type q at : prompt.

echo ">>> Count the number of top level keys: 2"
echo '{"a": 1, "b": 2}' | jq 'length'

echo ">>> Disply just the first issue array’s keys: assignee, etc."
echo ${foo} | jq '.[0] | keys' 

echo ">>> First issue array's first key: assignee "
echo ${foo} | jq '.[0] | keys | .[0]'

echo ">>> First (latest) issue ID: # 117446711"
echo ${foo} | jq '.[0].id'

echo ">>> Select: # A large blob is returned."
echo ${foo} | jq '.[] | select(.id==117446711)' | more



echo ">>> Slices an array on by index: # [ b, c ] "
echo '["a", "b", "c", "d"]' | jq '.[1:3]'


echo ">>> Return the index increment within the array: 1 for \"bar\" (the second item)"
echo '["foo","bar","bash"]' | jq 'index("bar")'

echo ">>> Return the index increment within the array:"
echo '"foo"' | jq 'index("oo")' 
   # 1 for "o" (the second char)

echo ">>> Nest ‘index’ inside ‘select’ explicitly:"
echo ${foo} | jq '.[] | select((.state|index("open")>=0))'
   # If the index value inside the current record’s labels for the value of “open” is greater than zero, 
   # select the record. 
   # Thankfully, the ‘select’ filter interprets numerical output as “true”, and null output as “false”, 
   # so we don’t have to be explicit, and we could rewrite that last command as:

echo ${foo} | jq '.[] | select(.state|index("open"))'
   # That looks a lot more like our ‘has’ which checks for the presence or keys. 
   # With ‘index’ and ‘has’ nested inside ‘select’, you have 
   #v about 80% of what you need to mangle JSON structures in shell for fun and profit. 
   # In fact, most of the query tools I’ve written to do things like 
   # resolve AWS Instance IP addresses from Tag Names use only what I’ve covered so far.  

# From here I would show you object construction (which I think of as wrappy brackets), and mapping, but 
# those two subjects really require an article of their own.


echo ">>> Flatten (Condense) a nested array into one: [1, 2, 3, 4]"
echo '[1, 2, [3, 4]]' | jq 'flatten'
 
