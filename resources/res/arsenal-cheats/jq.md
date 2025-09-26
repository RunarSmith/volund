
# jq

% js, json, query, cli

## pretty print
#platform/linux  #target/local  #cat/UTIL
```
cat headers.json | jq -r
```

## keys
#platform/linux  #target/local  #cat/UTIL
```
cat headers.json | jq -r '.headers | keys'
```

## search for users with role admin, and display their names
#platform/linux  #target/local  #cat/UTIL
```
cat users.json | jq -r '.users[] | select (.role="admin") | .name'
```

## number of elements in array
#platform/linux  #target/local  #cat/UTIL
```
cat users.json | jq -r '.users[] | length'
```

## for all users, show their name and roles
#platform/linux  #target/local  #cat/UTIL
```
cat users.json | jq -r '.users[] | "\(.name):\(role)"'
```
