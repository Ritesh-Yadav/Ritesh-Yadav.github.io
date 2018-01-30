---
title:  "Getting Valid SSL Certificate from Let's Encrypt for LocalHost"
categories: 
  - Tech
tags:
  - SSL
  - Letsencrypt
  - Heroku
  - Openssl
  - Localhost
  - Python
  - CertBot
---

As we are moving towards CI and CD, it's very important to have same environment configuration for different type of environments. In this post, I will explain a common problem related to local dev environment and valid SSL certificate.

{% include base_path %}

{% include toc title="Index" %}

## Problem Statement

When we use self signed certificate to enable SSL support for our applications in Local Dev environment, we face issue related to validity of that certificate. In order to fix the issue we have to do lots of work around like adding CA certificate in your trust store or ignoring the warning by browser etc. However, you can get a valid certificate from any valid Certificate Authority and that will make evrything go away. [Let’s Encrypt](https://letsencrypt.org/) is open source :heart: valid Certificate Authority which we are going to use in this case.

1. [Heroku Account](https://id.heroku.com/login) (Free account is good enough for this purpose)
2. [Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli)
3. Python 2.7 or greater
4. [Git CommandLine](https://desktop.github.com/) Desktop version has option to install commandline as well
5. [OpenSSL](https://www.openssl.org/)
6. Install [certbot](https://certbot.eff.org/) in your machine. I am going to use MacOS here, however the steps (except installation) would be same for any other operating system. You can run following command in MacOSX

```bash
$ brew install certbot
```

## Certificate Generation

Step 1. Please read and follow [Quick and Simple Web APP on Heroku Using Python Flask]({{ "/tech/quick-and-simple-web-app-on-heroku/" | absolute_url }})
{: #pr_step1}

Step 2. Once you have certbot installed, run following to get certificate

```bash
$ sudo certbot certonly --manual
```

Provide required information when promted by tool. When asked for domain name, enter FQDN (Fully Qualified Domain Name) of your app created in [Step 1](#pr_step1). It will ask to log your IP as well to public domain as you are asking for a certificate. After that you will see prompt like following asking `Press Enter to Continue`. Do not press enter yet.
{: #pr_step2}

{% include figure image_path="assets/images/getting-valid-ssl-certificate-for-localhost-from-letsencrypt/certbotOutput.jpg" alt="CertBot Output" %} 


Step 3. Now, we are going to use our [flask server app]({{ "/tech/quick-and-simple-web-app-on-heroku/#pfa_step4" | absolute_url }}) to host a page with details mentioned in above pic. I am going to user server.py file to enter details as follow:

```python
import os
from flask import Flask

app = Flask(__name__)

@app.route("/.well-known/acme-challenge/<copy last part of URL from certbot console>")
# e.g. /.well-known/acme-challenge/lzrajCaq8vbw5Qz2o_XXXXXXXXXXXXXXXXX
def hello():
    return "<copy data from certbot console>"
    # e.g. return "lzrajCaq8vbw5Qz2o_XXXXXXXXXXXXXXXXXXz4RnfWtLKaIc6EdhsOsr4fb6RFZuUoabZW5dPW36cmc"

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host='0.0.0.0', port=port)
```

Step 4. Run your `server.py` file to check it match the expectation mentioned by [certbot console output](#pr_step2)

Step 5. Push your [flask server app]({{ "/tech/quick-and-simple-web-app-on-heroku/#dth_step1" | absolute_url }}) to Heroku

Step 6. Now, go back to [certbot console](#pr_step2) and hit enter. After this, you would see location of your certificate created by Let's Encrypt. Letsencrypt will create the following certs:

* cert.pem
* chain.pem
* fullchain.pem
* privkey.pem

## CA and SSL Certificate

Once you get certifactes from Let's Encrypt, you can create Root CA certificate and certificate to use with your application. 

Step 1. Create certificate for your application. Inorder to do that you have to combine `privkey.pem` and `cert.pem`. You can use any text editor or command line. Here's the example of command line approach.

```bash
$ cd <location of your certificates>
$ cat privkey.pem cert.pem > myapp.pem
```

Step 2. In order to genearate CA certificate, you need to download IdenTrust DST Root CA X3 from https://www.identrust.com/certificates/trustid/root-download-x3.html. Save it to a file (e.g. `IdenTrustCA.crt`) and add `-----BEGIN CERTIFICATE-----` and `-----END CERTIFICATE-----` lines.

Step 3. Convert `IdenTrustCA.crt` this certificate to pem using openssl

```bash
$ openssl x509 -in IdenTrustCA.crt -out IdenTrustCA.pem -outform PEM
```

Step 4. Now combine `IdenTrustCA.pem` and `chain.pem`

```bash
cat IdenTrustCA.pem chain.pem > ca.pem
```

You should have something like following in your `ca.pem` file:

```java
-----BEGIN CERTIFICATE-----
MIIDSjCCAjKgAwIBAgIQRK+wgNajJ7qJMDmGLvhAazANBgkqhkiG9w0BAQUFADA/
MSQwIgYDVQQKExtEaWdpdGFsIFNpZ25hdHVyZSBUcnVzdCBDby4xFzAVBgNVBAMT
DkRTVCBSb290IENBIFgzMB4XDTAwMDkzMDIxMTIxOVoXDTIxMDkzMDE0MDExNVow
PzEkMCIGA1UEChMbRGlnaXRhbCBTaWduYXR1cmUgVHJ1c3QgQ28uMRcwFQYDVQQD
Ew5EU1QgUm9vdCBDQSBYMzCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
AN+v6ZdQCINXtMxiZfaQguzH0yxrMMpb7NnDfcdAwRgUi+DoM3ZJKuM/IUmTrE4O
rz5Iy2Xu/NMhD2XSKtkyj4zl93ewEnu1lcCJo6m67XMuegwGMoOifooUMM0RoOEq
OLl5CjH9UL2AZd+3UWODyOKIYepLYYHsUmu5ouJLGiifSKOeDNoJjj4XLh7dIN9b
xiqKqy69cK3FCxolkHRyxXtqqzTWMIn/5WgTe1QLyNau7Fqckh49ZLOMxt+/yUFw
7BZy1SbsOFU5Q9D8/RhcQPGX69Wam40dutolucbY38EVAjqr2m7xPi71XAicPNaD
aeQQmxkqtilX4+U9m5/wAl0CAwEAAaNCMEAwDwYDVR0TAQH/BAUwAwEB/zAOBgNV
HQ8BAf8EBAMCAQYwHQYDVR0OBBYEFMSnsaR7LHH62+FLkHX/xBVghYkQMA0GCSqG
SIb3DQEBBQUAA4IBAQCjGiybFwBcqR7uKGY3Or+Dxz9LwwmglSBd49lZRNI+DT69
ikugdB/OEIKcdBodfpga3csTS7MgROSR6cz8faXbauX+5v3gTt23ADq1cEmv8uXr
AvHRAosZy5Q6XkjEGB5YGV8eAlrwDPGxrancWYaLbumR9YbK+rlmM6pZW87ipxZz
R8srzJmwN0jP41ZL9c8PDHIyh8bwRLtTcm1D9SZImlJnt1ir/md2cXjbDaJWFBM5
JDGFoqgCWjBH4d1QB7wCCZAA62RjYJsWvIjJEubSfZGL+T0yjWW06XyxV3bqxbYo
Ob8VZRzI9neWagqNdwvYkQsEjgfbKbYK7p2CNTUQ
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIIEkjCCA3qgAwIBAgIQCgFBQgAAAVOFc2oLheynCDANBgkqhkiG9w0BAQsFADA/
MSQwIgYDVQQKExtEaWdpdGFsIFNpZ25hdHVyZSBUcnVzdCBDby4xFzAVBgNVBAMT
DkRTVCBSb290IENBIFgzMB4XDTE2MDMxNzE2NDA0NloXDTIxMDMxNzE2NDA0Nlow
SjELMAkGA1UEBhMCVVMxFjAUBgNVBAoTDUxldCdzI12uY3J5cHQxIzAhBgNVBAMT
GkxldCdzIEVuY3J5cHQgQXV0aG9yaXR5IFgzMIIBIjANBgkqhkiG9w0BAQEFAAOC
AQ8AMIIBCgKCAQEAnNMM8FrlLke3cl03g7NoYzDq1zUmGSXhvb418XCSL7e4S0EF
q6meNQhY7LEqxGiHC6PjdeTm86dicbp5gWAf15Gan/PQeGdxyGkOlZHP/uaZ6WA8
SMx+yk13EiSdRxta67nsHjcAHJyse6cF6s5K671B5TaYucv9bTyWaN8jKkKQDIZ0
Z8h/pZq4UmEUEz9l6YKHy9v6Dlb2honzhT+Xhq+w3Brvaw2VFn3EK6BlspkENnWA
a6xK8xuQSXgvopZPKiAlXQTGdMDQMc2PMTiVFrqoM7hD8bEfwzB/onkxEz0tNvjj
/PIzark5McWvxI0NHWQWM6r6hCm21AvA2H3DkwIDAQABo4IBfTCCAXkwEgYDVR0T
AQH/BAgwBgEB/wIBADAOBgNVHQ8BAf8EBAMCAYYwfwYIKwYBBQUHAQEEczBxMDIG
CCsGAQUFBzABhiZodHRwOi8vaXNyZy50cnVzdGlkLm9jc3AuaWRlbnRydXN0LmNv
bTA7BggrBgEFBQcwAoYvaHR0cDovL2FwcHMuaWRlbnRydXN0LmNvbS9yb290cy9k
c3Ryb290Y2F4My5wN2MwHwYDVR0jBBgwFoAUxKexpHsscfrb4UuQdf/EFWCFiRAw
VAYDVR0gBE0wSzAIBgZngQwBAgEwPwYLKwYBBAGC3xMBAQEwMDAuBggrBgEFBQcC
ARYiaHR0cDovL2Nwcy5yb290LXgxLmxldHNlbmNyeXB0Lm9yZzA8BgNVHR8ENTAz
MDGgL6AthitodHRwOi8vY3JsLXlkZW50cnVzdC5jb20vRFNUUk9PVENBWDNDUkwu
Y3JsMB0GA1UdDgQWBBSoSmpjBH3duubRObemRWXv86jsoTANBgkqhkiG9w0BAQsF
AAOCAQEA3TPXEfNjWDjdGBX7CVW+dla5cEilaUcne8IkCJLxWh9KEik3JHRRHGJo
uM2VcGfl96S8TihRzZvoroed6ti6WqEBmtzw3Wodatg+VyOeph4EYpr/1wXKtx8/
wApIvJSwtmVi4MFU5aMqrSDE6ea73Mj2tcMXX5jMd6jmeWUHK8so/joWUoHOUgwu
X4Po1QYz+3dszkDqMp4fklxBwXRsW10KXzPMTZ+sOPAveyxindmjkW8lGy+QsRlG
PfZ+G6Z6h7mjem0Y+iWlkYcV4PIWL1iwBi8saCbGS5jN2p8M+X+Q7UNKEkROb3N6
KOqkqm57TH2H3eDJAkSnh6/DNFu0Qg==
-----END CERTIFICATE-----
```

Step 5. Let's verify our app certificate with CA certificate

```bash
$ openssl verify -CAfile ca.pem myapp.pem
output: 
myapp.pem: OK
```

Congratulation now you have a valid certificate for your application.

## Local or Dev Machine Host Mapping

You need make sure that your dev machine IP or localhost is mapped to domain name you have used to obtian certificate. 

You can make entry in your `/etc/hosts` file to achive it

```bash
127.0.0.1           localhost ry-dev.herokuapp.com
```
