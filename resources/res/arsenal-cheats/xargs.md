
# xargs

% grep, search, cli

## all lines from source file separated by a space
#platform/linux  #target/local  #cat/UTIL
```
cat myfile.txt | xargs
```

## all lines from source file on a line with 5 elements
#platform/linux  #target/local  #cat/UTIL
```
cat myfile.txt | xargs -n 5
```

## execute command with each element - simple echo
#platform/linux  #target/local  #cat/UTIL
```
cat myfile.txt | xargs -I{} echo {}
```

## execute command with each element - dig
#platform/linux  #target/local  #cat/UTIL
```
cat myfile.txt | xargs -I{} dig +short {}
```
