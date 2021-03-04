---
title:  "Kong Developer Portal with Okta Open ID Connect (OIDC)"
categories: 
  - Tech
tags:
  - Kong
  - Okta
  - Api-Gateway
  - Setup-Guide
toc: true
toc_label: "Index"
toc_icon: "list-alt"
---

Kong is an open-source API Gateway tool. They also have an enterprise version that provides a developer portal feature.
The Kong Developer Portal provides a single source of truth for all developers to locate, access, and consume services.
For more details visit: [https://docs.konghq.com/enterprise/latest/developer-portal/](https://docs.konghq.com/enterprise/latest/developer-portal/)

{% include base_path %}

**Disclaimer**: I am **not** an expert in Okta or Kong. Please choose a security configuration as per your need and your company policies.
{: .notice--warning}

## Okta Configuration

We are going to set up an application and an authorization server in okta. Before we proceed with that login into your okta admin portal. Following is the step by step guide once you are at the okta admin portal:

### Add Application

1. Click on `Applications` tab
2. Click on `Add Application` button
   {% include figure image_path="assets/images/KongOktaDevPortal/OktaAddApplication.jpg" %}
3. On the next page, select `Web` and click on `Next`
   {% include figure image_path="assets/images/KongOktaDevPortal/OktaCreateNewApp1.jpg" %}
4. On the next page, give your application a name. Add a login redirect url which will be something like `https://<control-plane-hostname>:<portal_auth_port>/<workspace_name>/auth`. Assign a group to your application and click on `Done` button.
   {% include figure image_path="assets/images/KongOktaDevPortal/OktaCreateNewApp.jpg" %}
   **ProTip**: You can find portal port and portal auth port from Kong Admin api or console. In order to get the ports make get call to `https://<control-plane-hostname>:<admin_api_port>/<workspace_name>/kong`. Usually, if dev portal port number is 8442 then portal auth port number would be 8443.
   {: .notice--info}
5. On the next page, verify that you have correct values for all the URIs in `LOGIN` section. In my case, all three have same value.
  
   Also, note down `Client ID` and `Client Secret`, we need those when creating kong OIDC config.
   {: #okta_application }
   {% include figure image_path="assets/images/KongOktaDevPortal/OktaApplication.jpg" %}
6. That's all for adding an application.

### User Attributes

1. Click on the `Users` tab.
2. Search for a user in the search box.
3. Click on the username link.
   {% include figure image_path="assets/images/KongOktaDevPortal/OktaSearchUser.jpg" %}
4. On the next page, click on the `Profile` tab and check the attribute of the email address field.

   In my case, it was `login`. This is the value, we are going to use as [claim in authorization server](#okta_claims).
   {: #profile_attributes}
   {% include figure image_path="assets/images/KongOktaDevPortal/OktaProfile.jpg" %}

### Add Authorization Server

1. Click on the `API` tab.
2. Click on `Authorization Servers` option.
   {% include figure image_path="assets/images/KongOktaDevPortal/ApiAuthServers.jpg" %}
3. Click on `Authorization Servers` tab.
4. Click on `Add Authorization Server` button.
   {% include figure image_path="assets/images/KongOktaDevPortal/OktaAddAuthServer.jpg" %}
5. Fill authorization server `Name`, `Audience` and `Description` with any sensible value. Click on `Save`.
    {% include figure image_path="assets/images/KongOktaDevPortal/AddApiAuthServers.jpg" %}
6. On the next page, click on the `Settings` tab.

   Note down the `Custom URL` of the `Issuer`.
   {: #issuer_url}
   {% include figure image_path="assets/images/KongOktaDevPortal/OktaIssuerURL.jpg" %}
7. Click `Access Policies` tab.
8. Click `Add New Access Policy` button.
   {% include figure image_path="assets/images/KongOktaDevPortal/OktaAddAccessPolicies.jpg" %}
9.  Add a name and description for the policy. Search for the application in the `The following clients` box which was created earlier and add the app. Once the app is added, click the `Create Policy` button.
   {% include figure image_path="assets/images/KongOktaDevPortal/OktaAddPolicy.jpg" %}
11. Click `Claims` tab.
12. Click `Add Claim` button.
    {% include figure image_path="assets/images/KongOktaDevPortal/OktaClaims.jpg" %}
13. Fill `user.login` in name text box. Select `ID Token` and `Always` in `Include in token type` drop downs. 

    Fill `user.login` in `Value` text box. Also, select `Any scope` in `Include in` section and click `Save` button. See [profile attributes](#profile_attributes) for more details.
    {: #okta_claims}
    {% include figure image_path="assets/images/KongOktaDevPortal/OktaAddClaim.jpg" %}
14. Click `Add Rule` button.
    {% include figure image_path="assets/images/KongOktaDevPortal/OktaPolicyRule.jpg" %}
15. In the modal, add the rule name. Tick only the `Authorization Code` check box, select `Any user assigned the app` and `Any scopes`. Click on the `Create Rule` button.
    {% include figure image_path="assets/images/KongOktaDevPortal/OktaAddRule.jpg" %}
    **ProTip**: You can update access token lifetime, refresh token lifetime and expire as per your need.
    {: .notice--info}

## Kong Configuration

1. Login into the Kong admin portal.
2. Click on `Overview` in `Dev Portal` section, then click on `Turn On` button.
    {% include figure image_path="assets/images/KongOktaDevPortal/DevPortalOverview.jpg" %}
3. Click on `Settings` then click on `Authentication` tab.
4. Select `Open ID Connect` from the `Authentication plugin` dropdown.
5. Select `Custom` from the `Auth Config (JSON)` drop-down and paste the following config in the text area:

    ```json
    {
      "leeway": 1000,
      "consumer_by": [
          "username",
          "custom_id"
      ],
      "scopes": [
          "openid",
          "profile",
          "email",
          "offline_access"
      ],
      "logout_query_arg": "logout",
      "client_id": [
          "<enter_your_client_id>"
      ],
      "login_action": "redirect",
      "logout_redirect_uri": [
          "https://<control-plane-hostname>:<portal_port>/<workspace-name>/dashboard"
      ],
      "logout_methods": [
          "GET"
      ],
      "consumer_claim": [
          "user.login"
      ],
      "forbidden_redirect_uri": [
          "https://<control-plane-hostname>:<portal_port>/<workspace-name>/unauthorized"
      ],
      "issuer": "<issuer_custom_url>/.well-known/openid-configuration",
      "client_secret": [
          "<enter_your_client_secret>"
      ],
      "ssl_verify": false,
      "login_redirect_uri": [
          "https://<control-plane-hostname>:<portal_port>/<workspace-name>/dashboard"
      ],
      "login_redirect_mode": "query"
    }
   ```

   * Replace `<enter_your_client_id>` and `<enter_your_client_secret>` with actual value fetched from [okta application](#okta_application).
   * Replace `<control-plane-hostname>:<portal_port>/<workspace-name>` with the value shown in [dev portal overview page](#dev_portal_overview).
   * Value for `consumer_claim` should be same as claim added in okta [authorization server claims](#okta_claims).
   * Replace `<issuer_custom_url>` with the value fetched from [authorization server settings](#issuer_url).

6. Select `Enabled` from `Auto Approve Access` if you want to. This is an optional step.
7. Click on `Save Changes` button.
    {% include figure image_path="assets/images/KongOktaDevPortal/DevPortalSettings.jpg" %}
8. Click on `Overview` in `Dev Portal` section.

   Check the dev portal url and check that authentication is enabled.
   {: #dev_portal_overview}
   {% include figure image_path="assets/images/KongOktaDevPortal/PortalEnabled.jpg" %}

9. Once the portal is enabled, you should be able to register with the okta email address. If you have auto approve enabled for the users, then you should be able to login. Otherwise, you have to approve the user, and you should be able to login.

## Resources

* Developer Portal Docs: [https://docs.konghq.com/enterprise/latest/developer-portal/](https://docs.konghq.com/enterprise/latest/developer-portal/)
* OIDC Authentication: [https://docs.konghq.com/enterprise/latest/developer-portal/configuration/authentication/oidc/](https://docs.konghq.com/enterprise/latest/developer-portal/configuration/authentication/oidc/)
* OpenID Connect Plugin: [https://docs.konghq.com/hub/kong-inc/openid-connect/](https://docs.konghq.com/hub/kong-inc/openid-connect/)

Hope this guide will help you set up the integration between Kong and Okta.