package WebGUI::Asset::Wobject::WSClient;

use strict;
use Data::Dumper;
use Digest::MD5;
use SOAP::Lite;
use Storable;
use WebGUI::Cache;
use WebGUI::ErrorHandler;
use WebGUI::International;
use WebGUI::Macro;
use WebGUI::Paginator;
use WebGUI::Privilege;
use WebGUI::Session;
use WebGUI::Asset::Wobject;

my ($hasUnblessAcme, $hasUnblessData, $hasUtf8, $utf8FieldType);

# we really would like to be able to unbless references and strip utf8 data,
# but that requires non-standard and possibly difficult to install modules
BEGIN {

   # check for Data::Structure::Util, which requires perl 5.8.0 :-P
   eval { require Data::Structure::Util; };
   if ($@) {

      $utf8FieldType = 'hidden';

      # try Acme::Damn as partial fallback
      eval { require Acme::Damn; };
      $hasUnblessAcme = 1 if !$@;

   } else {

      $utf8FieldType = 'yesNo';
      $hasUnblessData = 1;
      $hasUtf8        = 1 if $] >= 5.008;
   }
}

our @ISA = qw(WebGUI::Asset::Wobject);


#-------------------------------------------------------------------
sub _create_cache_key {
   my ($wobject, $call, $param_str) = @_;
   my $cache_key;

   $cache_key = $_[0]->get('sharedCache')
      ? Digest::MD5::md5_hex($call, $param_str)
      : Digest::MD5::md5_hex($call, $param_str, $session{'var'}{'sessionId'});
   WebGUI::ErrorHandler::warn(($_[0]->get('sharedCache')?'shared':'session')
      . " cache_key=$cache_key md5_hex($call, $param_str)");
   return $cache_key;
}

#-------------------------------------------------------------------
sub definition {
	my $class = shift;
	my $definition = shift;
	my $httpHeaderFieldType;
   if ($session{'config'}{'soapHttpHeaderOverride'}) {
      $httpHeaderFieldType = 'text';
   } else {
      $httpHeaderFieldType = 'hidden';
   }
	push(@{$definition}, {
		tableName=>'WSClient',
		className=>'WebGUI::Asset::Wobject::WSClient',
		properties=>{
			templateId =>{
				fieldType=>"template",
				defaultValue=>'PBtmpl0000000000000069'
				},
         callMethod             => {
            fieldType     => 'textarea',
		defaultValue=>undef
         },
         debugMode        => {
            fieldType     => 'integer',
            defaultValue  => 0,
         },
         execute_by_default => {
            fieldType     => 'yesNo',
            defaultValue  => 1,
         },
         paginateAfter    => {
            defaultValue  => 100,
		fieldType=>"integer"
         },
         paginateVar    => {
            fieldType     => 'text',
		defaultValue=>undef
         },
         params           => {
            fieldType     => 'textarea',
         },
         preprocessMacros => {
            fieldType     => 'integer',
            defaultValue  => 0,
         },
         proxy            => {
            fieldType     => 'text',
            defaultValue  => $session{'config'}{'soapproxy'},
         },
         uri              => {
            fieldType     => 'text',
            defaultValue  => $session{'config'}{'soapuri'}
         },
         decodeUtf8       => {
            fieldType     => $utf8FieldType,
            defaultValue  => 0,
         },
         httpHeader       => {
            fieldType     => $httpHeaderFieldType,
		defaultValue=>undef
         },
         cacheTTL         => {
            fieldType     => 'integer',
            defaultValue  => 60,
         },
         sharedCache      => {
            fieldType     => 'integer',
            defaultValue  => '0',
         }
		}
		});
        return $class->SUPER::definition($definition);
}


#-------------------------------------------------------------------
sub getIcon {
	my $self = shift;
	my $small = shift;
	return $session{config}{extrasURL}.'/assets/small/web_services.gif' if ($small);
	return $session{config}{extrasURL}.'/assets/web_services.gif';
}

#-------------------------------------------------------------------
sub getName {
   return WebGUI::International::get(1, "WSClient");
}

#-------------------------------------------------------------------
sub getUiLevel {
	return 9;
}


#-------------------------------------------------------------------
sub getEditForm {
	my $self = shift;
	my $tabform = $self->SUPER::getEditForm();
   $tabform->getTab("display")->template(
      -name      => 'templateId',
      -value     => $self->getValue('templateId'),
      -namespace => "WSClient"
   );
   $tabform->getTab("display")->yesNo (
      -name  => 'preprocessMacros',
      -label => WebGUI::International::get(8, "WSClient"),
      -value => $self->get('preprocessMacros'),
   );
  	$tabform->getTab("display")->integer(
      -name  => 'paginateAfter',
      -label => WebGUI::International::get(13, "WSClient"),
      -value => $self->getValue("paginateAfter")
   );
   $tabform->getTab("display")->text (
      -name  => 'paginateVar',
      -label => WebGUI::International::get(14, "WSClient"),
      -value => $self->get('paginateVar'),
   );
   $tabform->getTab("properties")->text (
      -name  => 'uri',
      -label => WebGUI::International::get(2, "WSClient"),
      -value => $self->get('uri'),
   );
   $tabform->getTab("properties")->text (
      -name  => 'proxy',
      -label => WebGUI::International::get(3, "WSClient"),
      -value => $self->get('proxy'),
   );
   $tabform->getTab("properties")->text (
      -name  => 'callMethod',
      -label => WebGUI::International::get(4, "WSClient"),
      -value => $self->get('callMethod'),
   );
   $tabform->getTab("properties")->textarea ( 
      -name  => 'params',
      -label => WebGUI::International::get(5, "WSClient"),
      -value => $self->get('params'),
   );
   if ($session{'config'}{'soapHttpHeaderOverride'}) {
      $tabform->getTab("properties")->text (
         -name  => 'httpHeader',
         -label => WebGUI::International::get(16, "WSClient"),
         -value => $self->get('httpHeader'),
      );
   } else {
      $tabform->getTab("properties")->hidden (
         -name  => 'httpHeader',
         -label => WebGUI::International::get(16, "WSClient"),
         -value => $self->get('httpHeader'),
      );
   }
   $tabform->getTab("properties")->yesNo (
      -name  => 'execute_by_default',
      -label => WebGUI::International::get(11, "WSClient"),
      -value => $self->get('execute_by_default'),
   );
   $tabform->getTab("properties")->yesNo (
      -name  => 'debugMode',
      -label => WebGUI::International::get(9, "WSClient"),
      -value => $self->get('debugMode'),
   );
   if ($utf8FieldType eq 'yesNo') {
      $tabform->getTab("properties")->yesNo (
         -name  => 'decodeUtf8',
         -label => WebGUI::International::get(15, "WSClient"),
         -value => $self->get('decodeUtf8'),
      );
   } else {
      $tabform->getTab("properties")->hidden (
         -name  => 'decodeUtf8',
         -label => WebGUI::International::get(15, "WSClient"),
         -value => $self->get('decodeUtf8'),
      );
   }
   my $cacheopts = {
	0 => WebGUI::International::get(29, "WSClient"),
	1 => WebGUI::International::get(19, "WSClient"),
   };
   $tabform->getTab("properties")->radioList (
      -name    => 'sharedCache',
      -options => $cacheopts,
      -label   => WebGUI::International::get(28, "WSClient"),
      -value   => $self->get('sharedCache'),
   );
   $tabform->getTab("properties")->text (
      -name     => 'cacheTTL',
      -label    => WebGUI::International::get(27, "WSClient"),
      -value    => $self->get('cacheTTL'),
   );
	return $tabform;
}


#-------------------------------------------------------------------
sub www_edit {
        my $self = shift;
	return $self->getAdminConsole->render(WebGUI::Privilege::insufficient()) unless $self->canEdit;
	$self->getAdminConsole->setHelp("web services client add/edit");
        return $self->getAdminConsole->render($self->getEditForm->print,WebGUI::International::get("20","WSClient"));
}


#-------------------------------------------------------------------
sub view {
   my ( $arr_ref,                      # temp var holding params
        $cache_key,                    # unique cache identifier
        $cache,                        # cache object
        $call,                         # SOAP method call
	@exclude_params,               # input params NOT to pass to next pg
        $p,                            # pagination object
        $param_str,                    # raw SOAP params before parsing
        @params,                       # params to soap method call	
	$query_string,                 # query string to pass thru to next pg
        @result,                       # SOAP result reference	
	%seen,                         # counts diff bxt input & output params
        $soap,                         # SOAP object
        @targetWobjects,               # list of non-default wobjects to exec
        $url,                          # current page url
        %var                          # HTML::Template variables
   );
   my $self= shift;
   # this page, with important params
   $url = $self->getUrl("func=view");

    # This could belong up towards the top of the script, but it's nice to
    # have it down right close to the impacted code.  Add to this list params
    # that should never, ever be passed across multiple results pages
    @exclude_params = qw(cache func pn wid);

   # this page, with important params
    @seen{@exclude_params} = ();
    for (keys %{$session{'form'}}) {
       unless (exists $seen{$_}) {
          $query_string .= WebGUI::URL::escape($_) . '='
             . WebGUI::URL::escape($session{'form'}{$_}) . '&';
       }
    }
    $url = WebGUI::URL::page($query_string);


   # snag our SOAP call and preprocess if needed
   if ($self->get('preprocessMacros')) {
      $call = WebGUI::Macro::process($self->get("callMethod"));
      $param_str = WebGUI::Macro::process($self->get("params"));
    } else {
       $call        = $self->get('callMethod');
       $param_str   = $self->get('params');
   }

   # see if we can shortcircuit this whole process
   if ((ref $session{'form'}{'disableWobjects'} && grep /^$call$/,
         @{$session{'form'}{'disableWobjects'}}) ||
        ($session{'form'}{'disableWobjects'} && grep /^$call$/,
         $session{'form'}{'disableWobjects'})) {
                                                                                
      WebGUI::ErrorHandler::warn("disabling soap call $call");
      $var{'disableWobject'} = 1;
      return $self->processTemplate(\%var,$self->get("templateId"));
   }

   # advanced use, if you want to pass SOAP results to a single, particular
   # wobject on a page
   if (ref $session{'form'}{'targetWobjects'}) {
      @targetWobjects = @{$session{'form'}{'targetWobjects'}};
   } else {
      push @targetWobjects, $session{'form'}{'targetWobjects'};
   }

   # check to see if this exact query has already been cached, using either
   # a cache specific to this session, or a shared global cache
   if ($session{'form'}{'cache'}) {
      if ($session{'form'}{'targetWobjects'}
         && grep /^$call$/, @targetWobjects) {

         $cache_key = $session{'form'}{'cache'};
         WebGUI::ErrorHandler::warn("passed a cache_key for $call");
      } else {
         WebGUI::ErrorHandler::warn("cache_key not applicable to $call ");
         $cache_key = _create_cache_key($self, $call, $param_str);
      }
   } else {
      $cache_key = _create_cache_key($self, $call, $param_str);
   }
   $cache = WebGUI::Cache->new($cache_key,
      WebGUI::International::get(4, "WSClient"));

   # passing a form param WSClient_skipCache lets us ignore even good caches
   if (!$session{'form'}{'WSClient_skipCache'}) {
      @result = Storable::thaw($cache->get);
   }
   
   # prep SOAP unless we found cached data
   if (!$result[0]) {
      # this is the magic right here.  We're allowing perl to parse out 
      # the ArrayOfHash info so that we don't have to regex it ourselves
      # FIXME:  we need to protect against eval-ing unknown strings
      # the solution is to normalize all params to another table
      eval "\$arr_ref = [$param_str];";
      eval { @params = @$arr_ref; };
      WebGUI::ErrorHandler::warn(WebGUI::International::get(22, "WSClient")) if $@ && $self->get('debugMode');

      if ($self->get('execute_by_default') || grep /^$call$/,
         @targetWobjects) {

         # there's certainly a better pattern match than this to check for 
         # valid looking uri, but I haven't hunted for the relevant RFC yet
         if ($self->get("uri") =~ m!.+/.+!) {

            WebGUI::ErrorHandler::warn('uri=' . $self->get("uri"))
               if $self->get('debugMode');
            $soap = $self->_instantiate_soap;

         } else {
            WebGUI::ErrorHandler::warn(WebGUI::International::get(23, "WSClient")) if $self->get('debugMode');
         }
      }
   }

   # continue if our SOAP connection was successful or we have cached data
   if (defined $soap || $result[0]) {

      if (!$result[0]) {
         eval {
            # here's the rub.  `perldoc SOAP::Lite` says, "the method in
            # question will return the current object (if not stated
            # otherwise)".  That "not stated otherwise" bit is important.
            my $return = $soap->$call(@params);
         
            WebGUI::ErrorHandler::warn("$call(" . (join ',', @params) . ')')
               if $self->get('debugMode');

            # The possible return types I've come across include a SOAP object,
            # a hash reference, a blessed object or a simple scalar.  Each type
            # requires different handling (woohoo!) before being passed to the
            # template system
            WebGUI::ErrorHandler::warn(WebGUI::International::get(24, "WSClient") .  (ref $return ? ref $return : 'scalar')) if $self->get('debugMode');

            # SOAP object
            if ((ref $return) =~ /SOAP/i) {
               @result = $return->paramsall;

            # hashref
            } elsif (ref $return eq 'HASH') {
               @result = $return;

            # blessed object, to be stripped with Acme::Damn
            } elsif ($hasUnblessAcme && ref $return) {
               WebGUI::ErrorHandler::warn("Acme::Damn::unbless($return)");
               @result = Acme::Damn::unbless($return);

            # blessed object, to be stripped with Data::Structure::Util
            } elsif ($hasUnblessData && ref $return) {
               WebGUI::ErrorHandler::warn("Data::Structure::Util::unbless($return)");
               @result = Data::Structure::Util::unbless($return);

            # scalar value, we hope
            } else {
               # there's got to be a way to get into the SOAP body and find the
               # key name for the value returned, but I haven't figured it out
               @result = { 'result' => $return };
            }

            $cache->set(Storable::freeze(@result),
               $self->get('cacheTTL'));
         };

         # did the soap call fault?
         if ($@) {
            WebGUI::ErrorHandler::warn($@) if $self->get('debugMode');
            $var{'soapError'} = $@;
            WebGUI::ErrorHandler::warn(WebGUI::International::get(25, "WSClient") . $var{'soapError'})
               if $self->get('debugMode');
         }

      # cached data was found
      } else {
         WebGUI::ErrorHandler::warn("Using cached data");
      }

        WebGUI::ErrorHandler::warn(Dumper(@result)) if     
           $self->get('debugMode');

      # Do we need to decode utf8 data?  Will only decode if modules were
      # loaded and the wobject requests it
      if ($self->{'decodeUtf8'} && $hasUtf8) {
         if (Data::Structure::Util::has_utf8(\@result)) {
            @result = @{Data::Structure::Util::utf8_off(\@result)};
         }
      }

      # pagination is tricky because we don't know the specific portion of the
      # data we need to paginate.  Trust the user to have told us the right 
      # thing.  If not, try to Do The Right Thing
      if (scalar @result > 1) {
         # this case hasn't ever happened running against my dev SOAP::Lite
         # services, but let's assume it might.  If our results array has
         # more than one element, let's hope if contains scalars
         $p = WebGUI::Paginator->new($url, $self->get('paginateAfter'));
	$p->setDataByArrayRef(\@result);
         @result = ();
         @result = @$p;

      } else {

         # In my experience, the most common case.  We have an array
         # containing a single hashref for which we have been given a key name
         if (my $aref = $result[0]->{$self->get('paginateVar')}) {

            $var{'numResults'} = scalar @$aref;
            $p = WebGUI::Paginator->new($url,  $self->get('paginateAfter'));
		$p->setDataByArrayRef($aref);
            $result[0]->{$self->get('paginateVar')} = $p->getPageData;

         } else {

            if ((ref $result[0]) =~ /HASH/) {

               # this may not paginate the one that they want, but it will
               # prevent the wobject from dying
               for (keys %{$result[0]}) {
                  if ((ref $result[0]->{$_}) =~ /ARRAY/) {
                       $p = WebGUI::Paginator->new($url,  $self->get('paginateAfter'));
			$p->setDataByArrayRef($result[0]->{$_});
                     last;
                  }
               }
               $p ||= WebGUI::Paginator->new($url);
               $result[0]->{$_} = $p->getPageData;
               
            } elsif ((ref $result[0]) =~ /ARRAY/) {
               $p = WebGUI::Paginator->new($url, $self->get('paginateAfter'));
		$p->setDataByArrayRef($result[0]);
               $result[0] = $p->getPageData;

            } else {
               $p = WebGUI::Paginator->new($url, $self->get('paginateAfter'));
		$p->setDataByArrayRef([$result[0]]);
               $result[0] = $p->getPageData;
            }
         }
      }

      # set pagination links
      if ($p) {
	$p->appendTemplateVars(\%var);
         for ('pagination.firstPage','pagination.lastPage','pagination.nextPage','pagination.pageList',
		'pagination.previousPage', 'pagination.pageList.upTo20', 'pagination.pageList.upTo10') {
            $var{$_} =~ s/\?/\?cache=$cache_key\&/g;
         }
      }


   } else {
      WebGUI::ErrorHandler::warn(WebGUI::International::get(26, "WSClient") . $@) if $self->get('debugMode');
   }

   # did they request a funky http header?
   if ($session{'config'}{'soapHttpHeaderOverride'} &&
      $self->get("httpHeader")) {

      $session{'header'}{'mimetype'} = $self->get("httpHeader");
      WebGUI::ErrorHandler::warn("changed mimetype: " . 
         $session{'header'}{'mimetype'});
   }

   # Note, we still process our template below even though it will never
   # be displayed if the redirectURL is set.  Not sure how important it is
   # to do it this way, but it certainly is the least obtrusive to default
   # webgui flow.  This feature currently requires a patched WebGUI.pm file.
   if ($session{'form'}{'redirectURL'}) {
	WebGUI::HTTP::setRedirect($session{'form'}{'redirectURL'});
   }

   $var{'results'} = \@result;
   return $self->processTemplate(\%var, $self->get("templateId"));
}   


sub _instantiate_soap {
   my ($soap, @wobject);
   my $self = shift;

   # a wsdl file was specified
   # we don't use fault handling with wsdls becuase they seem to behave 
   # differently.  Not sure if that is by design.
     if ( ($self->get("uri") =~ m/\.wsdl\s*$/i) || ($self->get("uri") =~ m/\.\w*\?wsdl\s*$/i) ) {
      WebGUI::ErrorHandler::warn('wsdl=' . $self->get('uri'))
         if $self->get('debugMode');

      # instantiate SOAP service
      $soap = SOAP::Lite->service($self->get('uri'));
                                                                                
   # standard uri namespace
   } else {
      WebGUI::ErrorHandler::warn('uri=' . $self->get('uri'))
         if $self->get('debugMode');

      # instantiate SOAP service, with fault handling
      $soap = new SOAP::Lite     
         on_fault => sub {    
            my ($soap, $res) = @_;     
     	    die ref $res ? $res->faultstring : $soap->transport->status, "\n";
         };
      $soap->uri($self->get('uri'));
                                                                                
      # proxy the call if requested
      if ($self->get("proxy") && $soap) {

         WebGUI::ErrorHandler::warn('proxy=' . $self->get('proxy'))
            if $self->get('debugMode');
         $soap->proxy($self->get('proxy'),
            options => {compress_threshold => 10000});
      }
   }

   return $soap;
}
1;