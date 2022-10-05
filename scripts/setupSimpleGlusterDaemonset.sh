#! /bin/bash

kubectl delete -f ../k8s/daemonset-glusterd-debug.yaml
kubectl create -f ../k8s/daemonset-glusterd-debug.yaml

APPNAME="glusterd-debug"

# get all pod names for glusterd-debug daemonset
PODNAMES=$(kubectl get pods -l app=$APPNAME -o jsonpath='{.items[*].metadata.name}')

# wait until all the pods are ready
ALLPODSREADY=false

while [ $ALLPODSREADY == false ]; do
    echo "Waiting for all pods to be ready..."
    sleep 1
    ALLPODSREADY=true
    for PODNAME in $PODNAMES; do
        PODSTATUS=$(kubectl get pod $PODNAME -o jsonpath='{.status.phase}')
        if [ $PODSTATUS != "Running" ]; then
            ALLPODSREADY=false
        fi
    done
done

echo "All pods are ready!"

PODNAMES=$(kubectl get pods -l app=$APPNAME -o jsonpath='{.items[*].metadata.name}')

# fetch the IP addresses of all the pods
PODIPS=$(kubectl get pods -l app=$APPNAME -o jsonpath='{.items[*].status.podIP}')

echo "PODIPS: $PODIPS"

# peer probe all the pods
for PODIP in $PODIPS; do
    echo "Peer probing $PODIP"
    kubectl exec -it $PODNAMES -- gluster peer probe $PODIP
done

# get the first pod name

FIRSTPODNAME=$(kubectl get pods -l app=$APPNAME -o jsonpath='{.items[0].metadata.name}')

# get number of pods

NUMPODS=$(kubectl get pods -l app=$APPNAME -o jsonpath='{.items[*].metadata.name}' | wc -w)

# get the peer status from the first pod

kubectl exec -it $FIRSTPODNAME -- gluster peer status

VOLUME_DIRECTORY="/root/gv0"

# create the volume directory on all the pods

for PODNAME in $PODNAMES; do
    echo "Creating volume directory on $PODNAME"
    kubectl exec -it $PODNAME -- mkdir -p $VOLUME_DIRECTORY
done

# setup the volume creation string command

VOLUME_CREATION_COMMAND="gluster volume create gv0 replica $NUMPODS transport tcp "

for PODIP in $PODIPS; do
    VOLUME_CREATION_COMMAND="$VOLUME_CREATION_COMMAND $PODIP:$VOLUME_DIRECTORY"
done

echo "VOLUME_CREATION_COMMAND: $VOLUME_CREATION_COMMAND force"

# create the volume

kubectl exec -it $PODNAMES -- $VOLUME_CREATION_COMMAND force

# # start the volume

kubectl exec -it $PODNAMES -- gluster volume start gv0

# # get the volume info

kubectl exec -it $PODNAMES -- gluster volume info