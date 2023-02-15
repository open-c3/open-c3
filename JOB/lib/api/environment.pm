package api::environment;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use JSON qw();
use POSIX;
use MIME::Base64;
use api;

=pod

通知管理/获取所以环境变量

=cut

get '/environment' => sub {
    my $param = params();

    my $projectid = $param->{projectid};

    my $r = eval{ $api::mysql->query( "select `key`,`value` from openc3_job_environment")};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => +{ map{ @$_ }@$r } };
};

=pod

通知管理/提交变量状态

isApiFailEmail:false
isApiFailSms:false
isApiSuccessEmail:false
isApiSuccessSms:false
isApiWaitingEmail:false
isApiWaitingSms:false
isCrontabFailEmail:false
isCrontabFailSms:false
isCrontabSuccessEmail:false
isCrontabSuccessSms:false
isCrontabWaitingEmail:false
isCrontabWaitingSms:false
isPageFailEmail:false
isPageFailSms:false
isPageSuccessEmail:false
isPageSuccessSms:false
isPageWaitingEmail:false
isPageWaitingSms:false

notifyTemplateEmailTitle
notifyTemplateEmailContent
notifyTemplateSmsContent

=cut

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

    eval{ $api::auditlog->run( user => $user, title => 'EDIT ENVIRONMENT', content => "_" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    eval{ map{ $api::mysql->execute( "replace into openc3_job_environment (`key`,`value`,`create_user`)
        values('$_','$param->{$_}','$user')" ) }keys %$param; };

    return $@ ?  +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => scalar keys %$param };
};

=pod

通知管理/删除变量

参数:
  deletename1=1
  deletename2=1

=cut

del '/environment' => sub {
    my $param = params();

    return  +{ stat => $JSON::false, info => 'param null' } unless keys %$param;

    my $pmscheck = api::pmscheck( 'openc3_job_root' ); return $pmscheck if $pmscheck;

    map{ return  +{ stat => $JSON::false, info => "key name format error: $_" } unless $_ =~ /^[a-zA-Z0-9]+$/; }keys %$param;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    eval{ $api::auditlog->run( user => $user, title => 'EDIT ENVIRONMENT', content => "_" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    eval{ map{   $api::mysql->execute( "delete from openc3_job_environment where `key`='$_'" ); }keys %$param; }; 
    return $@ ?  +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => scalar keys %$param };
};

true;
