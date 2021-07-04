# Tools & Applications

Using the JSON API, various tools exist to interface with Password Pusher to automate password distribution.

We have no limits on how many passwords you can push (and have no intentions of adding limits) but we do have a rate limiter so the site doesn't get taken down by bad scripts or bad actors.  Limit your tools to maximum 1 password every few seconds and you should be fine.

# Slack

We don't have an official Slack application but it's fairly simple to add a custom slash command: [Slack: How to Add a Custom Slash Command](https://github.com/pglombardo/PasswordPusher/wiki/PasswordPusher-&-Slack:-Custom-Slash-Command)

![](https://disznc.s3.amazonaws.com/pwpush-slack.png)

## Command Line Utilities

Some great command line utilities written by the community.

* [pgarm/pwposh](https://github.com/pgarm/pwposh): a PowerShell module available in the [PowerShell Gallery](https://www.powershellgallery.com/packages/PwPoSh/)

*  [kprocyszyn/.Get-PasswordLink.ps1](https://github.com/kprocyszyn/tools/blob/master/Get-PasswordLink/Get-PasswordLink.ps1): a PowerShell based CLI

*  [lnfnunes/pwpush-cli](https://github.com/lnfnunes/pwpush-cli): a Node.js based CLI 

* [abkierstein/pwpush](https://github.com/abkierstein/pwpush): a Python based CLI

## Android Apps

*  [Pushie](https://play.google.com/store/apps/details?id=com.chesire.pushie) by [chesire](https://github.com/chesire)

## Other

* [Alfred Workflow](http://www.packal.org/workflow/passwordpusher) for Mac users

## Raw API

This API allows you to interface with Password Pusher via JSON.  This can be utilized by existing utilities such as curl, wget or even javascript.  See the examples below for some ideas.

* [The Password Pusher JSON API](https://github.com/pglombardo/PasswordPusher/wiki/Password-API)

### Examples

#### Curl

```
curl -X POST --data "password[payload]=mypassword&password[expire_after_days]=2&password[expire_after_views]=10" https://pwpush.com/p.json
```

#### Browser JS Console

You can test this in your browsers' Javascript console by going to the front page of Password Pusher and enter:

```
$.post('https://pwpush.com/p.json',
         { 'password[payload]': 'mypassword', 'password[expire_after_days]': '2',
           'password[expire_after_views]': '10' }, 
           function(data) { alert(data.url_token) } )
```

See more explanation and examples in our [Github Wiki](https://github.com/pglombardo/PasswordPusher/wiki/Password-API).