---
title:  "Quick and Simple Web APP on Heroku Using Python Flask"
comments: true
categories: 
  - Tech
tags:
  - Heroku
  - Python
  - Flask
toc: true
toc_label: "Index"
toc_icon: "list-alt"
---

In this post, I am going to show you how you can deploy a simple app in Heroku. It will be very quick if you have pre-requisite installed in your box. Let's jump on the business.

{% include base_path %}

## Prerequisites

1. [Heroku Account](https://id.heroku.com/login) (Free account is good enough for this purpose)
2. [Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli)
3. Python 2.7 or greater
4. [Git CommandLine](https://desktop.github.com/) Desktop version has option to install command line as well

## Create App in Heroku

**Step 1.** Log in to your Heroku account. After successful login, you will see dashboard page.

**Step 2.** Click on `New` ➝ `Create New App` option
{% include figure image_path="assets/images/quick-and-simple-web-app-on-heroku/HerokuDashboard.jpg" alt="Heroku Dashboard" %}

**Step 3.** Choose an app name for your app. You have to use this name to get SSL certificate. In my case, I am going to use `ry-dev`

**Step 4.** Now, select a region and create app.

**Step 5.** After creating app, you should see something like following screen:
{% include figure image_path="assets/images/quick-and-simple-web-app-on-heroku/HerokuDeploymentMethods.jpg" alt="Heroku Deployment Methods" %}

We are going to use Heroku Git for the purpose of this example. But you can try other options as well. Now follow the instructions mentioned for Heroku Git Deployment

{% include figure image_path="assets/images/quick-and-simple-web-app-on-heroku/HerokuGitDeployment.jpg" alt="Heroku Git Deployment" %}

After completing above steps. You should see your website **_\<APPNAME>_.herokuapp.com** (e.g. ry-dev.herokuapp.com) up and running in Heroku.

## Python Flask App

Now, we are going to create our page and deploy in Heroku.

**Pro Tip**: You can create python virtual environment on your local and try installing Flask in it.
{: .notice--info}

**Step 1.** Go to your app folder which was created earlier

**Step 2.** Install `flask` 

```bash
$ pip install flask
```

**Step 3.** Now, create a file with name `requirements.txt` and add following:

```python
Flask==0.12.2
Jinja2==2.9.6
MarkupSafe==1.0
Werkzeug==0.12.2
itsdangerous==0.24
```

This file is required by Heroku to install all the required packages.

**Note**: The version mentioned in the requirements file are the current version while writing this post. You can check your current version by `pip freeze` command.
{: .notice}

**Step 4.** Create python file (In my case, I am going to create `server.py`) and add following to the file:
{: #pfa_step4}

```python
import os
from flask import Flask

app = Flask(__name__)

@app.route("/")
def hello():
    return "I love this site!!!"

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host='0.0.0.0', port=port)
```

**Step 5.** Create a file with name `Procfile` and add following:

```yaml
web: python server.py
```

This file is required by Heroku to start your app.

**Step 6.** Let's try to run app in your local box before pushing it into Heroku. Run:

```bash
$ python server.py # server.py is my file name
```

You should see output like:

```bash
* Running on http://0.0.0.0:5000/ (Press CTRL+C to quit)
```

**Step 7.** Open `http://localhost:5000` and verify your site is up and running.

## Deploy to Heroku

Now, the final step in the process.

**Step 1.** Add your code into repository
{: #dth_step1}

```bash
$ git add .
$ git commit -am "Creating flask app"
```

**Step 2.** Push your code to Heroku

```bash
$ git push heroku master
```

**Step 3.** Now, You should see your website **_\<APPNAME>_.herokuapp.com** (e.g. ry-dev.herokuapp.com) up and running in Heroku.