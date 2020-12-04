package api::environment;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use JSON;
use POSIX;
use MIME::Base64;
use api;

get '/environment' => sub {
    my $param = params();

    my $projectid = $param->{projectid};

    my $r = eval{ $api::mysql->query( "select `key`,`value` from environment")};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => +{ map{ @$_ }@$r } };
};

##isApiFailEmail:false
##isApiFailSms:false
##isApiSuccessEmail:false
##isApiSuccessSms:false
##isApiWaitingEmail:false
##isApiWaitingSms:false
##isCrontabFailEmail:false
##isCrontabFailSms:false
##isCrontabSuccessEmail:false
##isCrontabSuccessSms:false
##isCrontabWaitingEmail:false
##isCrontabWaitingSms:false
##isPageFailEmail:false
##isPageFailSms:false
##isPageSuccessEmail:false
##isPageSuccessSms:false
##isPageWaitingEmail:false
##isPageWaitingSms:false
#
#notifyTemplateEmailTitle
#notifyTemplateEmailContent
#notifyTemplateSmsContent
post '/environment' => sub {
    my $param = params();

    return  +{ stat => $JSON::false, info => 'param null' } unless keys %$param;

    my $pmscheck = api::pmscheck( 'openc3_job_root' ); return $pmscheck if $pmscheck;

    for my $key ( keys %$param )
    {
        return  +{ stat => $JSON::false, info => "key name format error: $key" } unless $key =~ /^[a-zA-Z0-9]+$/;
        return  +{ stat => $JSON::false, info => "key value format error: $param->{$key}" } 
            if $param->{$key} =~ /'/;
    }

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    eval{ map{ $api::mysql->execute( "replace into environment (`key`,`value`,`create_user`)
        values('$_','$param->{$_}','$user')" ) }keys %$param; };

    return $@ ?  +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => scalar keys %$param };
};

#deletename1=1
#deletename2=1
del '/environment' => sub {
    my $param = params();

    return  +{ stat => $JSON::false, info => 'param null' } unless keys %$param;

    my $pmscheck = api::pmscheck( 'openc3_job_root' ); return $pmscheck if $pmscheck;

    map{ return  +{ stat => $JSON::false, info => "key name format error: $_" } unless $_ =~ /^[a-zA-Z0-9]+$/; }keys %$param;

    eval{ map{   $api::mysql->execute( "delete from environment where `key`='$_'" ); }keys %$param; }; 
    return $@ ?  +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => scalar keys %$param };
};

true;
