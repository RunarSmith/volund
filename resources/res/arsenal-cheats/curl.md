
# curl

% curl, web, cli

## show headers
#plateform/linux #target/local #cat/UTILS
```
curl -i http://<domain>
```

## http HEAD
#plateform/linux #target/local #cat/UTILS
```
curl -I http://<domain>
```

## POST with json data
#plateform/linux #target/local #cat/UTILS
```
curl -H 'Content-Type: application/json' http://<domain> -X POST -d '{"test":"test123"}'
```

## basic Auth
#plateform/linux #target/local #cat/UTILS
```
curl -i http://<domain> -u user1:secret1
```

## output to file
#plateform/linux #target/local #cat/UTILS
```
curl http://<domain>  -o <output_file>
```
