=head1 NAME

ECPDF::BaseClass

=head1 AUTHOR

Electric Cloud

=head1 DESCRIPTION

ECPDF::BaseClass is the base class for the classes across ECPDF SDK.

This class creates in runtime accessors for class properties and creates a new() method as constructor.

This class was designed for internal usage for developers of ECPDF Perl SDK.

=head1 USAGE

To use base class one need to:

=over 4

=item Create a class

=item Make this class as base using use base

=item Create classDefinition() method which returns a hashref with class definition.

=back

=head1 USAGE

%%%LANG=perl%%%
    package MyClass;
    use base qw/ECPDF::BaseClass/;
    use strict;
    sub classDefinition {
        return {
            name => 'str',
            value => 'str'
        };
    }

    1;
%%%LANG%%%

After this class has been created, you can use it and have an accessors/constructors.

%%%LANG=perl%%%
    use MyClass;
    my $object = MyClass->new({name => 'one', value => 'two'});
    # name = one
    my $name = $object->getName();
    # value = two
    my $value = $object->getValue();
%%%LANG%%%

=cut

package ECPDF::BaseClass;

use strict;
use warnings;
use Data::Dumper;
use Carp;
use ECPDF::Log;
use ECPDF::Helpers qw/bailOut/;

our $AUTOLOAD;

sub AUTOLOAD {
    my ($class, @args) = @_;

    if (!$class->can('classDefinition')) {
        bailOut("classDefinition method should be set to make this working.");
    }
    my $method = $AUTOLOAD;
    $method =~ s/.*:://;
    my $definition = $class->classDefinition();
    if ($method eq 'new') {
        my $object = __checkParams($class, $definition, @args);

        bless $object, $class;
        return $object;
    }
    if ($method eq 'get' || $method eq 'set') {
        my $msg = "$method is not defined. ";
        if ($method eq 'get' && $args[0]) {
            my $method = ucfirst($args[0]);
            $method = "get$method()";
            $msg .= sprintf(q|To get a value of '%s' field of '%s' %s->%s should be used.|, $args[0], ref $class, ref $class, $method);
        }
        elsif ($method eq 'set' && $args[0] && $args[1]) {
            my $method = ucfirst($args[0]);
            $method = "set$method";
            $msg .= sprintf('To get a value of %s field of class, %s(%s) should be used', $args[0], $method, $args[1]);
        }
        bailOut($msg);
    }
    if ($method =~ m/^get(.*?)$/s) {
        my $field = $1;

        $field = __returnFieldName($class, $field, $definition);
        return __get($class, $definition, $field, @args);
    }
    if ($method =~ m/^set(.*?)$/s) {
        my $field = $1;

        $field = __returnFieldName($class, $field, $definition);
        return __set($class, $definition, $field, @args);
    }

    bailOut("Unknown method '$method' in class '$class'");

}

# This function is empty for a reason.
# TODO: Add reference about autoload and DESTROY handles from perldoc.
sub DESTROY {}
sub import {}
sub __get {
    my ($object, $definition, $field, $opts) = @_;

    if (!$field) {
        bailOut("Field $field is mandatory.");
    }
    my $rv = undef;
    if (defined $object->{$field}) {
        $rv = $object->{$field};
        return $rv;
    }
    # TODO: improve error handling here.
    # if ($opts->{nonFatal}) {
    # croak "Field $field does not exist";
    #}
    return undef;
}

sub __set {
    my ($object, $definition, $field, $value, $opts) = @_;

    if (!$field) {
        croak "Field is mandatory";
    }
    if (!$definition->{$field}) {
        croak "Field $field is not allowed in " . ref $object . "\n";
    }

    if ($definition->{$field} =~ m/^[A-Z]/s && (!ref $value || ref $value ne $definition->{$field})) {
        croak "Value for $field is expected to be a $definition->{field}, but not a " . ref $value;
    }
    $object->{$field} = $value;
    return $object;
}

sub __checkParams {
    my ($class, $definition, $params) = @_;
    for my $k (keys %$params) {
        if (!$definition->{$k}) {
            croak "Key $k is not defined for $class\n";
        }
        my $value = $params->{$k};
        if ($definition->{$k} =~ m/^[A-Z]/s && (!ref $value || ref $value ne $definition->{$k})) {
            my $ref = ref $value || 'unblessed reference';
            croak "Value for $k is expected to be a type of $definition->{$k}, but not a " . $ref;
        }
    }
    return $params;
}

sub __returnFieldName {
    my ($class, $field, $definition) = @_;

    $field = lcfirst $field;
    if (!$definition->{$field}) {
        croak "Field $field does not exist in class $class";
    }

    return $field;
}


1;
