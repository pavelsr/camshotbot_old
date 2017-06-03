#!/usr/bin/env perl
# Telegram bot that send you a snapshot from IP camera using ffmpeg

package CamshotBot;

use Mojolicious::Lite;
use WWW::Telegram::BotAPI;
use Data::Dumper;
use Net::Ping;
use Date::Format;
use Telegram::Bot::Message;

my $config = plugin 'Config' => { file => 'camshotbot.conf' };
plugin( 'Webtail', file => $config->{log_file} );
# https://metacpan.org/pod/Mojolicious::Plugin::Webtail

BEGIN { $ENV{TELEGRAM_BOTAPI_DEBUG}=1 };
my $api = WWW::Telegram::BotAPI->new (
    token => $config->{telegram_api_token}
);

my $bot_name = $api->getMe->{result}{username};
my $filename = $config->{last_shot_filename};
my $stream_url = $config->{stream_url};
my $cmd = 'ffmpeg -hide_banner -loglevel panic -i '.$stream_url.' -f image2 -vframes 1 '.$filename;

sub random_caption {
	my @array = @{$config->{random}};
	my $index  = rand @array;
	my $element = $array[$index];
	return $element;
};



helper answer => sub {
	my ($c, $update) = @_;

	app->log->info("Processing new update...");
	my $mo = Telegram::Bot::Message->create_from_hash($update->{message});
	
	my $msg = $mo->text;
  	my $chat_id = $mo->chat->id;
  	my $from_id = $mo->from->id;
  	my $date = $mo->date;
  	my $date_str = time2str("%R %a %o %b %Y" ,$mo->date); # 11:59 Sun 29th Jan 2017

  	# Loggging
	if ($config->{debug}) {
		# full log, convenient if you need to restict chat_id's and check what's wrong
		app->log->info("Update from Telegram API: ".Dumper $update);
		app->log->info("Update parsed by Telegram::Bot::Message: ".Dumper $mo);
	} else {
		my $from_str = '';
		my $username = $mo->from->username;
		if ($username) {
			$from_str = $username;
		} else {
			$from_str = $mo->from->first_name." ".$mo->from->first_name." (id ".$from_id.")";
		}
		app->log->info($msg." from ".$from_str." sent at ".$date_str);
	};

  	`rm -f $filename`; # remove old screenshot
   	my $o = `$cmd`;

 	app->log->info("Screenshot got with command: ".$cmd.', result : '.$o);
   
   	if ( ($msg eq "/shot") || ($msg eq '/shot@'.$bot_name )) {
			
		$api->sendPhoto ({
		    chat_id => $chat_id,
		    photo   => {
		        file => $filename
		    },
		    caption => random_caption(),
		    reply_to_message_id => $mo->message_id
		});
	}

	if ($msg eq "/help") {
		
		$api->sendMessage ({
		    chat_id => $chat_id,
		    text => '/shot - Get online camera shot',
		    reply_to_message_id => $mo->message_id
		});
	}

};

# for local testing purposes. also shows how many unprocessed updates in queue on server
helper check_for_updates => sub {
	my $c = shift;
	my $res = $api->deleteWebhook() ; # disable webhooks
	# warn Dumper $res;
	my $updates = $api->getUpdates();
	my $h = { 
		updates_in_queue => {} 
	};
	$h->{updates_in_queue}{count} = scalar @{$updates->{result}};
	$h->{updates_in_queue}{details} = \@{$updates->{result}};

	my @u_ids;
	for (@{$updates->{result}}) {
		push @u_ids, $_->{update_id};
	}

	$h->{updates_in_queue}{update_ids} = \@u_ids;

	$c->setWebhook() if !($config->{polling}); # set Webhook again if needed

	return $h;
};

helper setWebhook => sub {
	my $c = shift;
	return $api->setWebhook({ url => $config->{bot_domain}.'/'.$config->{telegram_api_token} });
};


post '/'.$config->{telegram_api_token} => sub {
  my $c = shift;
  my $update = $c->req->json;
  $c->answer($update);
  $c->render(json => "ok");
};

get '/' => sub {
	shift->render(text => 'bot is running');
};

get '/status' => sub {
	my $c = shift;
	my $status = {};
	$status->{telegram_api} = eval { $api->getMe } or $status->{telegram_api} = $api->parse_error->{msg};
	my $p = Net::Ping->new();
	$status->{vpn_status} = 'down';
	$status->{vpn_status} = 'up' if $p->ping($config->{vpn_ip});
	$status->{WebhookInfo} = $api->getWebhookInfo;
	$p->close();
	$c->render(json => $status);
};

get '/setwebhook' => sub {
	my $c = shift;
	my $res = $c->setWebhook();
	$c->render( json => $res );
};

# shows info about unprocessed updates on server
get '/debug' => sub {
	my $c = shift; # $c = Mojolicious::Controller object
	$c->render( json => $c->check_for_updates() );
};




if ($config->{polling}) {
	
	my $res = $api->deleteWebhook();
	app->log->info("Webhook was deleted. Starting polling with ".$config->{polling_timeout}."secs timeout ...") if $res;

	Mojo::IOLoop->recurring($config->{polling_timeout} => sub {

		my @updates = @{$api->getUpdates->{result}};

		if (@updates) { 	
			for my $u (@updates) {
				app->build_controller->answer($u); # Mojolicious::Lite ->  Mojolicious::Controller -> Mojolicious::Helper
			}
		}
	
	});
}

my $queue = app->build_controller->check_for_updates()->{updates_in_queue};

app->log->info('Starting bot @'.$bot_name."...");
app->log->info("Having ".$queue->{count}." stored Updates at Telegram server");
app->log->info("Unprocessed update ids (for offset debug): ".join(',', @{$queue->{update_ids}}) );
app->start;