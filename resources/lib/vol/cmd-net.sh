# network tools

# PUBLIC net cert: show certificate
cert(){
  local p=443
  if [ -n "$2" ]; then
    p=$2;
  fi

  </dev/null openssl s_client -showcerts -connect $1:443 2>/dev/null | \
    openssl x509 -noout -subject -fingerprint \
      -ext subjectAltName \
      -issuer \
      -dates  
}

# PUBLIC net sitecert: show site certificate
sitecert() {
  leafcert $1 $2 | openssl x509 -text -noout
}

# PUBLIC net leafcert: show leaf certificate
leafcert() {
  local p=443
  local chain=""

  if [ x"${1}" = x"full" ]; then
    chain="-showcerts"
    shift
  fi

  if [ -n "$2" ]; then
    p=$2;
  fi
  </dev/null openssl s_client ${chain} -connect $1:$p 2>/dev/null | \
    awk '
      # Certificate begins with -----BEGIN CERTIFICATE-----
      # and ends with -----END CERTIFICATE-----
      /-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/ {
        print
      }'
}

# PUBLIC net fullchain: show fullchain
fullchain() {
  leafcert full $1 $2
}
