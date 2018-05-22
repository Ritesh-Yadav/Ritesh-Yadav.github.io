---
title:  "Setup iTerm with Oh-My-Zsh and Plugins"
categories: 
  - Tech
tags:
  - iTerm
  - Oh-My-Zsh
  - Zsh
  - Productivity
  - Fira-Code
  - Ligature
---

As a software engineer, we spend significant amount of time in terminal. Mac OSX provide terminal better than 
windows terminal but it's not as good as iTerm2. If you combine iTerm with Zsh and Oh-My-Zsh then you get awesomeness.

{% include base_path %}

{% include toc title="Index" %}

## iTerm2

Download a stable build from https://www.iterm2.com/downloads.html and install it.

## Brew

[Homebrew](https://brew.sh/) is a free and open-source software package management system that simplifies the 
installation of software on Apple's macOS operating system.

Now, open iTerm and install `brew` using following command:

```bash
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

## Fira Code Font

Fira Code is an extension of the Fira Mono font containing a set of ligatures for common programming multi-character combinations. 
This is just a font rendering feature: underlying code remains ASCII-compatible. This helps to read and understand code faster.

### Without Fira Code

{% include figure image_path="assets/images/setup-iterm-with-oh-my-zsh/without-fira-code.png" %}

### With Fira Code

{% include figure image_path="assets/images/setup-iterm-with-oh-my-zsh/with-fira-code.png" %}

To install Fira Code, run following command:

```bash
brew cask install font-fira-code
```

**ProTip**: Fira Code font is supported in multiple editors and terminals. Checkout complete list on [Fira Code site](https://github.com/tonsky/FiraCode)
{: .notice--info}

### Setup Font in iTerm

**Step 1.** Open `Preferences` in iTerm by pressing <kbd>⌘</kbd> and <kbd>,</kbd> keys

**Step 2.** Go to `Profile` tab and create a new profile
  {% include figure image_path="assets/images/setup-iterm-with-oh-my-zsh/create_profile.gif" %}

**Step 3.** Go to `Text` tab. Change font and ASCII font to `Fira Code` and enable use of ligature
  {% include figure image_path="assets/images/setup-iterm-with-oh-my-zsh/select_font.gif" %}

## Zsh

Once you have `brew` installed, you can install `zsh` using following command:

```bash
brew install zsh
```

## Oh-My-Zsh

[Oh-My-Zsh](http://ohmyz.sh/) is an open source, community-driven framework for managing your ZSH configuration. 
It comes bundled with a ton of helpful functions, helpers, plugins, themes and much more.

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
```

### Set Theme

There are whole lot of themes to choose from [here](https://github.com/robbyrussell/oh-my-zsh/wiki/Themes). 
Change `ZSH_THEME=robbyrussell` to `ZSH_THEME=YOUR_FAV_THEME_NAME` into `~/.zshrc` file. After change reload shell by:

```bash
source ~/.zshrc
```

### Enable plugins

There's an abundance of plugin in Oh-my-zsh. You can find list of plugins [here](https://github.com/robbyrussell/oh-my-zsh/wiki/Plugins).
Most of the plugins provide autocompletion for command options on press of <kbd>⇥ tab</kbd> key ([demo](#plugin_demo)). You can turn on plugins by updating `plugins` section in `~/.zshrc` file like following:

```bash
plugins=(brew git ruby aws virtualenv)
```

Install zsh syntax highlighting and auto suggestions plugins if you are interested in these functionality.

```bash
brew install zsh-syntax-highlighting zsh-autosuggestions
```

Add following lines to end of the `~/.zshrc` file. You can pick and choose from last 3 lines, based on the plugin you have installed.

```bash
export VIRTUAL_ENV_DISABLE_PROMPT=
export LC_CTYPE=en_GB.UTF-8
export TERM="xterm-256color"
export ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor line)
source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
```

**ProTip**: To reload any change in `~/.zshrc` file use `source ~/.zshrc` command.
{: .notice--info #plugin_demo}
{% include figure image_path="assets/images/setup-iterm-with-oh-my-zsh/plugins_demo.gif" %}

## Alias

Alias is not exclusive funtionality of zsh but Oh-my-zsh provides lots of alias by default. Lots of plugins also come with alias for example `git` plugin.

If you want to create your on aliases, create a separate file and load that file using `~/.zshrc` by adding following line in the file:

```bash
source PATH_TO_YOUR_FILE
```

To list all the avaliable alias use command `alias` in the terminal.

## HotKeys

If your hotkeys for moving backward (<kbd>⌥ option</kbd> + <kbd>←</kbd>) and forward (<kbd>⌥ option</kbd> + <kbd>→</kbd>) word by word do not work in iTerm then change keys preset in your profile to `Natural Text Editing`.

{% include figure image_path="assets/images/setup-iterm-with-oh-my-zsh/keys_preset.gif" %}

 