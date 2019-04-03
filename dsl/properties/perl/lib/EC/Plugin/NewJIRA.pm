package EC::Plugin::NewJIRA;
use strict;
use warnings;
use base qw/ECPDF/;
use Data::Dumper;
use ECPDF::Log;
use ECPDF::ComponentManager;
# Feel free to use new libraries here, e.g. use File::Temp;

# Service function that is being used to set some metadata for a plugin.
sub pluginInfo {
    return {
        pluginName    => '@PLUGIN_KEY@',
        pluginVersion => '@PLUGIN_VERSION@',
        configFields  => ['config'],
        configLocations => ['ec_plugin_cfgs'],
        pluginValues    => {
            oauth => {
                request_method         => 'POST',
                oauth_signature_method => 'RSA-SHA1',
                oauth_version          => '1.0',
                request_token_path     => 'plugins/servlet/oauth/request-token',
                authorize_token_path   => 'plugins/servlet/oauth/authorize',
                access_token_path      => 'plugins/servlet/oauth/access-token',
            }
        }
    };
}

# Auto-generated method for the procedure Get Issue/Get Issue
# Add your code into this method and it will be called when step runs
sub getIssue {
    my ($pluginObject) = @_;
    my $context = $pluginObject->newContext();
    my $params = $context->getRuntimeParameters();
    print Dumper $params;
    my $restClientCreationParams = {};
    if ($params->{authType} eq 'OAuth1.0') {
        logInfo("Using oauth");
        my $oauthValues = $pluginObject->getPluginValues()->{oauth};

        $oauthValues->{private_key} = $params->{password};
        $oauthValues->{oauth_token} = $params->{user};
        $oauthValues->{oauth_consumer_key} = $params->{oauthConsumerKey};
        $oauthValues->{base_url} = $params->{jiraUrl};

        $restClientCreationParams->{oauth} = $oauthValues;
        logDebug("Created REST client creation params: ", Dumper $restClientCreationParams);
    }

    # newRESTClient automatically loads OAuth component
    my $rest = $context->newRESTClient($restClientCreationParams);

    print Dumper $params;

    my $jiraUrl = $pluginObject->buildJiraAPIUrl($context);
    $jiraUrl .= '/issue/' . $params->{issueId};
    logInfo("Built jira URL: $jiraUrl");
    if ($params->{authType} eq 'OAuth1.0') {
        my $oauth = ECPDF::ComponentManager->getComponent('ECPDF::Component::OAuth');
        my $requestParams = $oauth->augment_params_with_oauth('GET', $jiraUrl, {});
        $jiraUrl = $rest->augmentUrlWithParams($jiraUrl, $requestParams);
    }

    my $request = $rest->newRequest(GET => $jiraUrl);
    if ($params->{authType} eq 'Basic') {
        $request->authorization_basic($params->{user}, $params->{password});
    }
    my $response = $rest->doRequest($request);

    my $stepResult = $context->newStepResult();

    $stepResult->setJobSummary("Got issue.");
    $stepResult->setJobStepSummary('And this is a job step summary');

    $stepResult->setOutputParameter('issue', $response->decoded_content());
    $stepResult->apply();
}
## === step ends ===
# Please do not remove the marker above, it is used to place new procedures into this file.

sub createRequest {
    my ($self) = @_;

    my $pluginValues = $self->getPluginValues();

    print Dumper $pluginValues;
    
}

sub buildJiraAPIUrl {
    my ($self, $context) = @_;

    my $params = $context->getRuntimeParameters();
    my $jiraUrl = $params->{jiraUrl};
    $jiraUrl =~ s/\/$//gs;
    $jiraUrl .= '/rest/api/2';
    return $jiraUrl;
}

1;
