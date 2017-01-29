Telegram bot that send you a snapshot from IP camera using ffmpeg

In addition sends random funny phrase as shapshot caption from random key of camshotbot.conf

# Setup

## 1. Install ffmpeg

``sudo apt-get install ffmpeg``


## 2. Install dependencies

go to root bot folder and run  ``sudo cpanm --installdeps .``

If you don't have cpanm at your system install it with:  ``sudo cpan App::cpanminus``


## 3. Check that camera is available

Bot requires that you must be able to get a screenshot from camera on server where bot is running by single command

Bot was created specially for @FabLab61.

At @FabLab61 there is an Xiaomi YI Ants IP webcamera. 

Server has access to camera via VPN so we can get a screenshot using ffmpeg by following command:

``ffmpeg -hide_banner -loglevel panic -i rtsp://10.132.193.9//ch0.h264 -f image2 -vframes 1 test.jpg``

You can execute this command locally to check camera

Also you can open a stream url (like ``rtsp://10.132.193.9//ch0.h2640``) in vlc to check that speed of video straming is enough and delay isn't so big 


## 4. Edit camshotbot.conf

Example:

```perl
{
  hypnotoad => {
    listen  => ['http://*:8099']
  },
  random => [
    "How beautiful FabLab looks like, isnt it?",
    "Don't be a dick, clean up that mess!",
    "Common sense is not so common... ;)",
   	"Just do it",
   	"We make porn here",
   	"FabLab is priceless, for other things we have MasterCard",
   	"Don't judge a book by its cover",
   	"There will be clean when pigs fly",
   	"Space where you can wear your heart on your sleeve",
   	"Silicon Valley for hardware",
   	"Do-ocracy born here",
   	"Don't govern. Just do",
   	"Fuck a day keeps the doctor away",
   	"Quick and dirty",
   	"Curiosity killed the cat",
   	"FabLab - pushing the envelope",
   	"FabLab - where the bodies are buried",
   	"Learn by doing",
   	"Life is short. Do stuff that matters"
  ],
  telegram_api_token => '267111731:AAHJSqyyjbVBh0pAOr677WoUxi-juMpWKto',
  polling => 0,		# set to 0 if you want to work via webhooks
  polling_timeout => 3,
  last_shot_filename => 'latest.jpg',
  vpn_ip => '10.132.193.9', # for /status output
  stream_url => 'rtsp://10.132.193.9//ch0.h264',
  bot_domain => 'https://camerabot.fablab61.ru', # needed for webhooks. must be https
  log_file => 'log/production.log',
  debug => 1
};

```

## 5. Run bot with hypnotoad

``hyphotoad camshotbot.pl``


## 6. Setup webhooks

1. Get bot available via http at some domain

2. Run domain over https only with Let's encrypt

``a@FabServer:~# sudo ./certbot-auto --nginx -d camerabot.fablab61.ru``

3. Check that ``bot_domain`` set at camshotbot.conf

4. Run get request ``camshotbot.pl get /setwebhook`` (or do it via web browser)


# Development guidelines

If using polling in order to avoid getting duplicate updates, recalculate offset after each server response




# FAQ

## Why my bot isn't working or working with errors?

Check ``camshotbot.pl get /setwebhook`` output. It will show potential problems with VPN or Telegram API

Normally result must be like

```javascript
{"telegram_api":{"ok":true,"result":{"first_name":"FabLab61 get camshot","id":267111731,"username":"camshot_bot"}},"vpn_status":"up"}
```

Also you can check

<bot_domain>/webtail page

and files in ``log`` folder using ``tail -f`` option


## Can I use non IP camera?

Yes. For that you need to edit ``$cmd`` variable



