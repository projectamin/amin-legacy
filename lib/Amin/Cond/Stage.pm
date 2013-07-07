package Amin::Cond::Stage;

#A Stage

use strict;
use vars qw(@ISA);
use Amin::Elt;

@ISA = qw(Amin::Elt);

sub stages {
    my $self = shift;
    $self->{STAGES} = shift if @_;
    if ($self->{STAGES}) {
        return $self->{STAGES};
    } else {
        #initial stages
        my %stages = (
            "apackage" => 1,
            "ainit" => 1,
        );
        return \%stages;
    }
}


sub state {
    my $self = shift;
    $self->{STATE} = shift if @_;
    if ($self->{STATE}) {
        return $self->{STATE};
    } else {
        #initial state
        return 0;
}

sub localname {
    return "stage";
}

sub start_element {
    my ($self, $element) = @_;
    my %attrs = %{$element->{Attributes}};
    $self->attrs(\%attrs);

    my $local = $self->localname;
    my $state = $self->state;
    my $stages = $self->stages;
    my $param = $self->{Spec}->{Filter_Param};
    my $log = $self->{Spec}->{Log};
    if (($element->{Prefix} eq $stages->{$element->{Prefix}}) && 
        ($element->{LocalName} eq $local))
    {
        $self->command($local);
        if ($attrs{'{}name'}->{Value} eq $param) {
            $self->stage($attrs{'{}name'}->{Value});
            $state = 0;
            $self->SUPER::start_element($element);
        } else {
            $state = 1;
            $log->driver_start_element($element->{Name}, %attrs);
        }
    }
    if ($state == 1) {
        unless ($element->{LocalName} eq $local) {
            $log->driver_start_element($element->{Name}, %attrs);
        }
    } else {
        unless ($element->{LocalName} eq $local) {
            $self->SUPER::start_element($element);
        }
    }
}

sub characters {
    my ($self, $chars) = @_;
    my $data = $chars->{Data};
    my $log = $self->{Handler}->{Spec}->{Log};
    $data = $self->fix_text($data);
    if (($self->command eq $local) && ($data ne "")) {
        if ($state == 1) {
            $log->driver_characters($data);
        } else {
            $self->SUPER::characters($chars);
        }
    }
}

sub end_element {
    my ($self, $element) = @_;
    my $attrs = $self->attrs;
    my $param = $self->{Spec}->{Filter_Param};
    my $log = $self->{Spec}->{Log};

    if (($element->{LocalName} eq $local) && ($self->command eq $local)) {
        if ($self->stage eq $param) {
            $state = 1;
            $self->SUPER::end_element($element);
        } else {
            $state = 0;
            $log->driver_end_element($element->{Name});
        }
    }
    if ($state == 1) {
        unless ($element->{LocalName} eq $local) {
            $log->driver_end_element($element->{Name});
        }
    } else {
        unless ($element->{LocalName} eq $local) {
            $self->SUPER::end_element($element);
        }
    }
}

sub version {
    return "1.2";
}

sub stage {
    my $self = shift;
    $self->{STAGE} = shift if @_;
    return $self->{STAGE};
}

1;


=head1 NAME
 
Amin::Stage - generic reader class filter

=head1 DESCRIPTION

  A generic reader class for any <*:stage name=""> element.

  If the stages method is not set with a referenced hash, then the default
  adistro controllers are supplied as the * stages.

  Name is supplied via the controller to the machine. This is known 
  as a controller/machine filter_param. 

  ex. start stage with the apackage controller
  
  apackage -u file://my/profile.xml -x source_install
  
  Your controller can also set the filter_param(s) internally and 
  there may be no need for typing out filter_param(s). Please consult
  your controller documentation. 
  
=head1 XML

=over 4

=item Full example

 <apackage:stage name="start" >
     <amin:command name="mkdir">
       <amin:param>/tmp/apackage-start</amin:param>
     </amin:command>
 </apackage:stage>
 <apackage:stage name="stop" >
     <amin:command name="mkdir">
       <amin:param>/tmp/apackage-stop</amin:param>
     </amin:command>
 </apackage:stage>
 <!-- and so on-->

=back  

=cut