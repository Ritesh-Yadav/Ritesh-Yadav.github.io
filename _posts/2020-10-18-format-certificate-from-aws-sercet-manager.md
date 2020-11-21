---
title:  "Get formatted certificate from AWS secret manager"
comments: true
categories: 
  - Tech
tags:
  - aws
  - secret-manager
  - ssm
  - Bash
  - tricks
  - awk
  - sed
---

Get formatted certificate from AWS secret manager using different methods.

{% include base_path %}

{% include toc title="Index" %}

## Problem Statement

When you save certificates in AWS secret manager then it removes all the newline characters which means if you get the certificate later from secret manager it's not properly formatted. e.g.

```json
{
    "Name": "my-fake-certificate-and-key",
    "VersionId": "9ffe116e-7740-4096-b8ca-5217c6417823",
    "SecretString": "{\"certificate\":\"-----BEGIN CERTIFICATE----- MIICvDCCAiWgAwIBAgIURRLTUS8M410YQSbLw6ikm20d2VcwDQYJKoZIhvcNAQEL BQAwcDELMAkGA1UEBhMCVVMxDzANBgNVBAgMBk9yZWdvbjERMA8GA1UEBwwIUG9y dGxhbmQxFTATBgNVBAoMDENvbXBhbnkgTmFtZTEMMAoGA1UECwwDT3JnMRgwFgYD VQQDDA93d3cuZXhhbXBsZS5jb20wHhcNMjAxMTIwMTkzMDE0WhcNMjExMTIwMTkz VR0OBBYEFNXwO1c8ibaIVMaue4ZxKF7LvxyQMB8GA1UdIwQYMBaAFNXwO1c8ibaI VMaue4ZxKF7LvxyQMA8GA1UdEwEB/wQFMAMBAf8wDQYJKoZIhvcNAQELBQADgYEA Rh5UeR29i8kYSNtU2VRGnHYAK8s9FQy5GG3/lMWbzN1B/XJbIxlbTd+ZIXi/bq8L jR/OmvJS8UA7mJahUKJ4N2g9EvtuOcMjxl7BKE2bh8+3nt5Izd/05Bo/XcISlYWc R2G+w0QowQUVOCwyZcqB6gTyNSVy0rUKrssqRJX1qTk= -----END CERTIFICATE-----\", \"key\": \"-----BEGIN RSA PRIVATE KEY----- MIIC1DBOBgkqhkiG9w0BBQ0wQTApBgkqhkiG9w0BBQwwHAQIZ5X0htdHmJECAggA MAwGCCqGSIb3DQIJBQAwFAYIKoZIhvcNAwcECNFM5lixm1GfBIICgIBtV5Ig0h0I 8wzJfx4ffO3fjsy/qDg14zj5rHK3QlT11SW92AFrMYvmkKNzVBb8pOK1yQFjrM8m 9QBa1Kr3rfQ1CPiljm6XJahLKZ5ev/FmvQEx9KNo7be55+KAJ0uo+S+xRdgMP/Nf lecSRWGns30VsESDrXA9fbt8jdNyNEEAkMruAMajHNzSgQcOWHERt/Go6nWnEYBJ gifV6uSnCZXO6BZFYI28cubimX5LRISJY4HFDwp/desFJkzgPk5VWyrvOS2hYbW/ z9dgW4/lONK9cv/ktL9Yz9ZwmxlX9xGoPGC0hZ+U3nM1L6S322DC9wW23oYTbOE4 FOd+GTIAEXA07/o3chg09J7b+8aGw7ehN+P6WTO5n+pCLaV7Vg63hmodiktcp8VQ FS/iOVg1OhcE5gIKxbptrc5gryBrsX38WNuXryTBzJkHiptAbi99AfdlelaDA+iN QQn/QgWuPRQ= -----END RSA PRIVATE KEY-----\"}",
    "VersionStages": [
        "AWSCURRENT"
    ],
    "CreatedDate": 1603049779.11,
    "ARN": "arn:aws:secretsmanager:us-east-1:123456789:secret:my-fake-certificate-and-key-XQuwafs"
}
```

In this post, I am going to discuss about different approach to solve this problem.

## Using Base64 encoding

Encode certificate and key before saving it into secret manager.

```bash
$ base64 private_key > encoded_private_key
$ base64 certificate > encoded_certificate
```

When you want to download and use the certificate, just decode back. Certificate and key would be properly formatted. Following is the bash script to do so:

```bash
#!/bin/bash
certificate_secrets_file="secrets_file"
aws secretsmanager get-secret-value --secret-id "arn:aws:secretsmanager:us-east-1:123456789:secret:my-fake-certificate-and-key-XQuwafs" --query "SecretString" --output text > "$certificate_secrets_file"

cat "$certificate_secrets_file" | jq .key | tr -d '"' | base64 -D > "private_key"
cat "$certificate_secrets_file" | jq .certificate | tr -d '"' | base64 -D > "certificate"
```

{% capture notice-1 %}
**Pro Tip:** `jq .key | tr -d '"'` can be replaced with `sed -n 's|.*"key"[[:space:]]*:[[:space:]]*"\([^"]*\).*|\1|p'` and `jq .certificate | tr -d '"'` can be replaced with `sed -n 's|.*"certificate"[[:space:]]*:[[:space:]]*"\([^"]*\).*|\1|p'` if **jq** can not be used for any reason.

**SED Explanation**:

- -n is for don't output
- s\|\<pattern\>\|\<replace\>\|p for search, match pattern, replace and print
- \| is used as separator instead of / to make it easier to read
- Group match between brackets \( ... \), later accessible with \1,\2...
- Followed by anything in brackets [], [ab/] would mean either a or b or /
- ^ in [] means not, so followed by anything but the thing in the [], so [^\"] means anything except \" character. This pattern can be think of as non-greedy pattern.
- \* is to repeat previous group so [^/]* means characters except \"
- value in json ends by \" so the group match should stop on the next \". So far `sed -n 's|.*"certificate"[[:space:]]*:[[:space:]]*"\([^"]*\)` means search and remember value of certificate until next \"
- Also, match the rest of the line after the whole value matches so we add .*
- now the group 1 (\1), which has the value of certificate, will replace the whole matched pattern and print: `sed -n 's|.*"certificate"[[:space:]]*:[[:space:]]*"\([^"]*\).*|\1|p'`

```html
Pattern match: {"certificate":"-----BEGIN CERTIFICATE----- MIICvDCCAiWgAwIBAgIURRLTUS8M410YQSbLw6ikm20d2VcwDQYJKoZIhvcNAQEL BQAwcDELMAkGA1UEBhMCVVMxDzANBgNVBAgMBk9yZWdvbjERMA8GA1UEBwwIUG9y dGxhbmQxFTATBgNVBAoMDENvbXBhbnkgTmFtZTEMMAoGA1UECwwDT3JnMRgwFgYD VQQDDA93d3cuZXhhbXBsZS5jb20wHhcNMjAxMTIwMTkzMDE0WhcNMjExMTIwMTkz VR0OBBYEFNXwO1c8ibaIVMaue4ZxKF7LvxyQMB8GA1UdIwQYMBaAFNXwO1c8ibaI VMaue4ZxKF7LvxyQMA8GA1UdEwEB/wQFMAMBAf8wDQYJKoZIhvcNAQELBQADgYEA Rh5UeR29i8kYSNtU2VRGnHYAK8s9FQy5GG3/lMWbzN1B/XJbIxlbTd+ZIXi/bq8L jR/OmvJS8UA7mJahUKJ4N2g9EvtuOcMjxl7BKE2bh8+3nt5Izd/05Bo/XcISlYWc R2G+w0QowQUVOCwyZcqB6gTyNSVy0rUKrssqRJX1qTk= -----END CERTIFICATE-----", "key": "-----BEGIN RSA PRIVATE KEY----- MIIC1DBOBgkqhkiG9w0BBQ0wQTApBgkqhkiG9w0BBQwwHAQIZ5X0htdHmJECAggA MAwGCCqGSIb3DQIJBQAwFAYIKoZIhvcNAwcECNFM5lixm1GfBIICgIBtV5Ig0h0I 8wzJfx4ffO3fjsy/qDg14zj5rHK3QlT11SW92AFrMYvmkKNzVBb8pOK1yQFjrM8m 9QBa1Kr3rfQ1CPiljm6XJahLKZ5ev/FmvQEx9KNo7be55+KAJ0uo+S+xRdgMP/Nf lecSRWGns30VsESDrXA9fbt8jdNyNEEAkMruAMajHNzSgQcOWHERt/Go6nWnEYBJ gifV6uSnCZXO6BZFYI28cubimX5LRISJY4HFDwp/desFJkzgPk5VWyrvOS2hYbW/ z9dgW4/lONK9cv/ktL9Yz9ZwmxlX9xGoPGC0hZ+U3nM1L6S322DC9wW23oYTbOE4 FOd+GTIAEXA07/o3chg09J7b+8aGw7ehN+P6WTO5n+pCLaV7Vg63hmodiktcp8VQ FS/iOVg1OhcE5gIKxbptrc5gryBrsX38WNuXryTBzJkHiptAbi99AfdlelaDA+iN QQn/QgWuPRQ= -----END RSA PRIVATE KEY-----"}
Group 1: -----BEGIN CERTIFICATE----- MIICvDCCAiWgAwIBAgIURRLTUS8M410YQSbLw6ikm20d2VcwDQYJKoZIhvcNAQEL BQAwcDELMAkGA1UEBhMCVVMxDzANBgNVBAgMBk9yZWdvbjERMA8GA1UEBwwIUG9y dGxhbmQxFTATBgNVBAoMDENvbXBhbnkgTmFtZTEMMAoGA1UECwwDT3JnMRgwFgYD VQQDDA93d3cuZXhhbXBsZS5jb20wHhcNMjAxMTIwMTkzMDE0WhcNMjExMTIwMTkz VR0OBBYEFNXwO1c8ibaIVMaue4ZxKF7LvxyQMB8GA1UdIwQYMBaAFNXwO1c8ibaI VMaue4ZxKF7LvxyQMA8GA1UdEwEB/wQFMAMBAf8wDQYJKoZIhvcNAQELBQADgYEA Rh5UeR29i8kYSNtU2VRGnHYAK8s9FQy5GG3/lMWbzN1B/XJbIxlbTd+ZIXi/bq8L jR/OmvJS8UA7mJahUKJ4N2g9EvtuOcMjxl7BKE2bh8+3nt5Izd/05Bo/XcISlYWc R2G+w0QowQUVOCwyZcqB6gTyNSVy0rUKrssqRJX1qTk= -----END CERTIFICATE-----
```
{% endcapture %}

<div class="notice" id="notice1">
  {{ notice-1 | markdownify }}
</div>

## Using AWK

For some reason if you can not use [Base64 encoding](#using-base64-encoding) then you can use **awk** to format the certificate and key.

```bash
#!/bin/bash
certificate_secrets_file="secrets_file"
aws secretsmanager get-secret-value --secret-id "arn:aws:secretsmanager:us-east-1:123456789:secret:my-fake-certificate-and-key-XQuwafs" --query "SecretString" --output text > "$certificate_secrets_file"

cat "$certificate_secrets_file" | jq .key | tr -d '"' | awk 'BEGIN {RS=" "} /BEGIN|END|RSA|PRIVATE/ {printf $0 " "}; !/BEGIN|END|RSA|PRIVATE/ {print $0}' > "private_key"
cat "$certificate_secrets_file" | jq .certificate | tr -d '"' | awk 'BEGIN {RS=" "} /BEGIN|END/ {printf $0 " "}; !/BEGIN|END/ {print $0}' > "certificate"
```

{% capture notice-2 %}
**AWK Explanation**:

- `BEGIN {RS=" "}` sets record separator to space instead of default newline and it's executed only once
- `/BEGIN|END/ {printf $0 " "}` means that if record contains BEGIN or END then print in the same line with space as printf doesn't print newline character by default
- `!/BEGIN|END/ {print $0}` means that if record doesn't contain BEGIN or END then print with newline

so the output is:
```html
-----BEGIN CERTIFICATE-----
MIICvDCCAiWgAwIBAgIURRLTUS8M410YQSbLw6ikm20d2VcwDQYJKoZIhvcNAQEL
BQAwcDELMAkGA1UEBhMCVVMxDzANBgNVBAgMBk9yZWdvbjERMA8GA1UEBwwIUG9y
dGxhbmQxFTATBgNVBAoMDENvbXBhbnkgTmFtZTEMMAoGA1UECwwDT3JnMRgwFgYD
VQQDDA93d3cuZXhhbXBsZS5jb20wHhcNMjAxMTIwMTkzMDE0WhcNMjExMTIwMTkz
VR0OBBYEFNXwO1c8ibaIVMaue4ZxKF7LvxyQMB8GA1UdIwQYMBaAFNXwO1c8ibaI
VMaue4ZxKF7LvxyQMA8GA1UdEwEBwQFMAMBAf8wDQYJKoZIhvcNAQELBQADgYEA
Rh5UeR29i8kYSNtU2VRGnHYAK8s9FQy5GG3/lMWbzN1B/XJbIxlbTd+ZIXi/bq8L
jR/OmvJS8UA7mJahUKJ4N2g9EvtuOcMjxl7BKE2bh8+3nt5Izd/05Bo/XcISlYWc
R2G+w0QowQUVOCwyZcqB6gTyNSVy0rUKrssqRJX1qTk=
-----END CERTIFICATE-----
```
{% endcapture %}

<div class="notice" id="notice2">
  {{ notice-2 | markdownify }}
</div>

Again, if you can not use **jq** for any reason see [Pro Tip](#notice1) for alternative option.

## Programming Language

In programming language which supports negative lookahead. Following psudo-code with regex can be used to remove all the spaces and format the cert:

```javascript
replace(/ (?!(RSA|PRIVATE|KEY))/g, '\n')

replace(/ (?!(CERTIFICATE))/g, '\n')
```
