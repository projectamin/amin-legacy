package Amin::Machine;

use strict;
use warnings;

use vars qw(@ISA);
use Amin::Elt;
@ISA = qw(Amin::Elt);

sub process_adminlist {
    my ($self, $cli) = @_;

    my $adminlist = $self->parse_adminlist($cli->adminlist);

    my $adminlist_map;
    if($cli->adminlist_map) {
        $adminlist_map = $self->parse_adminlistmap($cli->adminlist_map);
    }
    my @types = qw(map profile adminlist);
    my $profiles, $adminlists,$networkmap;
    if (defined $adminlist_map) {
        $profiles, $adminlists, $networkmap = $self->get_types(\@types, $adminlist_map, $key);
        $profiles, $networkmap = $self->get_adminlists($profiles, $adminlists, $networkmap, $adminlist_map);
    } else {
        #no mapping
        $profiles, $adminlists, $networkmap = $self->get_types(\@types, $adminlist, $key);
        $profiles, $networkmap = $self->get_adminlists($profiles, $adminlists, $networkmap);
    }

    foreach my $profile (@$profiles) {
        $otext .= $self->process_profile($cli, $profile, $networkmap);
    }
    return $otext;
}

sub process_profile {
    my ($self, $cli, $profile_in, $networkmap_in, $uri_in) = @_;
    my $m = $self->get_machine($cli);
    my $out;
    my $networkmap = $cli->networkmap || $networkmap_in;
    my $profile = $cli->profile || $profile_in;
    my $profile = $cli->uri || $uri_in;

    if ($uri) {
        if ($networkmap) {
            my $nm = $p->parse_networkmap($networkmap);
            foreach my $networkmap (keys %$nm) {
                my $protocol = $nm->{$networkmap}->{protocol};
                $out .= $protocol->parse_uri($nm->{$networkmap}, $uri);
            }
        } else {
            $out = $m->parse_uri($uri);
        }
    } else {
        if ($networkmap) {
            my $nm = $self->parse_networkmap($networkmap);
            foreach my $networkmap (keys %$nm) {
                my $protocol = $nm->{$networkmap}->{protocol};
                $out .= $protocol->parse_string($nm->{$networkmap}, $profile);
            }
        } else {
            $out = $m->parse_string($profile);
        }
    }
    my $text = $self->parse_CLIOutput($out);
    return $text;
}

1;
