#!/bin/sh

# Add custom facts to fake being a virt-who guest
if [ -n "$UUID" ]; then
    echo "Adding guest config with UUID: $UUID."
    echo "{\"virt.host_type\": \"vmware\", \"virt.uuid\": \"$UUID\", \"virt.is_guest\": \"True\"}" > /etc/rhsm/facts/guest.facts
fi

# Add the Satellite's cert
if [ -n "$SATHOST" ]; then
    echo "Adding satellite certificate http://$SATHOST/pub/katello-ca-consumer-latest.noarch.rpm"
    rpm -Uvh http://$SATHOST/pub/katello-ca-consumer-latest.noarch.rpm
fi

# Configure our registration auth, if provided
if [ -n "$AUTH" ]; then
    IFS="/" read -r UNAME PWORD <<< "$AUTH"
    AUTH='--username="$UNAME" --password="$PWORD"'
else
    AUTH="--username="admin" --password="changeme""
fi

# Set the organization to default, if not provided
if [ -z "$ORG" ]; then
    ORG="Default_Organization"
fi

# Register to the sat if an activation key specified
if [ -n "$AK" ]; then
    echo "Activation key $AK found. Registering..."
    subscription-manager register --org="$ORG" --activationkey="$AK"
# If an environment is otherwise specified, use it
elif [ -n "$ENV" ]; then
    echo "Environment $ENV found. Registering..."
    subscription-manager register --org="$ORG" --environment="$ENV" $AUTH
# If no specifics are provided, register to the library
else
    echo "No registration details specified. Registering to $ORG and Library..."
    subscription-manager register --org="$ORG" --environment="Library" $AUTH
fi

# If an activation key wasn't used, and we are a virt guest
if [ -z "$AK"] && [ -n "$UUID" ]; then
    echo "Attempting to auto-attach a subscription."
    subscription-manager attach --auto
fi


# Install katello agent
yum -y install katello-agent

# if the KILL arg was not passed, then keep the container running
if [ -z "$KILL" ]; then
    echo "Starting goferd in foreground."
    goferd -f
    tail -f /var/log/rhsm/rhsm.log
fi
